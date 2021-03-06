
/* Copyright 2014 United States Government as represented by the
 * Administrator of the National Aeronautics and Space
 * Administration. No copyright is claimed in the United States under
 * Title 17, U.S. Code.  All Other Rights Reserved.
 *
 * The refine platform is licensed under the Apache License, Version
 * 2.0 (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>

#include "ref_layer.h"
#include "ref_split.h"

#include "ref_malloc.h"
#include "ref_math.h"
#include "ref_mpi.h"
#include "ref_validation.h"

REF_STATUS ref_layer_create(REF_LAYER *ref_layer_ptr, REF_MPI ref_mpi) {
  REF_LAYER ref_layer;

  ref_malloc(*ref_layer_ptr, 1, REF_LAYER_STRUCT);

  ref_layer = *ref_layer_ptr;

  RSS(ref_list_create(&(ref_layer_list(ref_layer))), "create list");
  RSS(ref_grid_create(&(ref_layer_grid(ref_layer)), ref_mpi), "create grid");

  ref_layer->nnode_per_layer = REF_EMPTY;
  ref_layer->verbose = REF_FALSE;

  return REF_SUCCESS;
}

REF_STATUS ref_layer_free(REF_LAYER ref_layer) {
  if (NULL == (void *)ref_layer) return REF_NULL;

  ref_grid_free(ref_layer_grid(ref_layer));
  ref_list_free(ref_layer_list(ref_layer));
  ref_free(ref_layer);

  return REF_SUCCESS;
}

REF_STATUS ref_layer_attach(REF_LAYER ref_layer, REF_GRID ref_grid,
                            REF_INT faceid) {
  REF_CELL ref_cell = ref_grid_tri(ref_grid);
  REF_INT cell, nodes[REF_CELL_MAX_SIZE_PER];

  /* copy nodes into local copy that provides compact index */
  each_ref_cell_valid_cell_with_nodes(
      ref_cell, cell, nodes) if (faceid == nodes[ref_cell_node_per(ref_cell)])
      RSS(ref_list_push(ref_layer_list(ref_layer), cell), "parent");

  return REF_SUCCESS;
}

REF_STATUS ref_layer_normal(REF_LAYER ref_layer, REF_GRID ref_grid,
                            REF_INT node, REF_DBL *norm) {
  REF_CELL ref_cell = ref_grid_tri(ref_grid);
  REF_INT i, item, cell, nodes[REF_CELL_MAX_SIZE_PER];
  REF_BOOL contains;
  REF_DBL angle, total, triangle_norm[3];

  total = 0.0;
  norm[0] = 0.0;
  norm[1] = 0.0;
  norm[2] = 0.0;

  each_ref_cell_having_node(ref_cell, node, item, cell) {
    RSS(ref_list_contains(ref_layer_list(ref_layer), cell, &contains),
        "in layer");
    if (!contains) continue;
    RSS(ref_cell_nodes(ref_cell, cell, nodes), "tri nodes");
    RSS(ref_node_tri_node_angle(ref_grid_node(ref_grid), nodes, node, &angle),
        "angle");
    RSS(ref_node_tri_normal(ref_grid_node(ref_grid), nodes, triangle_norm),
        "norm");
    RSS(ref_math_normalize(triangle_norm), "normalize tri norm");
    total += angle;
    for (i = 0; i < 3; i++) norm[i] += angle * triangle_norm[i];
  }

  if (!ref_math_divisible(norm[0], total) ||
      !ref_math_divisible(norm[1], total) ||
      !ref_math_divisible(norm[2], total))
    return REF_DIV_ZERO;

  for (i = 0; i < 3; i++) norm[i] /= angle;

  RSS(ref_math_normalize(norm), "normalize average norm");

  return REF_SUCCESS;
}

REF_STATUS ref_layer_puff(REF_LAYER ref_layer, REF_GRID ref_grid) {
  REF_CELL ref_cell = ref_grid_tri(ref_grid);
  REF_NODE layer_node = ref_grid_node(ref_layer_grid(ref_layer));
  REF_CELL layer_prism = ref_grid_pri(ref_layer_grid(ref_layer));
  REF_CELL layer_edge = ref_grid_edg(ref_layer_grid(ref_layer));
  REF_INT item, cell, cell_node, cell_edge, nodes[REF_CELL_MAX_SIZE_PER];
  REF_INT prism[REF_CELL_MAX_SIZE_PER];
  REF_INT new_cell;
  REF_INT node, local, global, i, nnode_per_layer;
  REF_DBL norm[3];

  /* first layer of nodes */
  each_ref_list_item(ref_layer_list(ref_layer), item) {
    cell = ref_list_value(ref_layer_list(ref_layer), item);
    RSS(ref_cell_nodes(ref_cell, cell, nodes), "nodes");
    each_ref_cell_cell_node(ref_cell, cell_node) {
      RSS(ref_node_add(layer_node, nodes[cell_node], &node), "add");
      for (i = 0; i < 3; i++)
        ref_node_xyz(layer_node, i, node) =
            ref_node_xyz(ref_grid_node(ref_grid), i, nodes[cell_node]);
    }
  }
  nnode_per_layer = ref_node_n(layer_node);
  ref_layer->nnode_per_layer = nnode_per_layer;

  /* second layer of nodes */
  for (local = 0; local < nnode_per_layer; local++) {
    global = local + ref_node_n_global(ref_grid_node(ref_grid));
    RSS(ref_node_add(layer_node, global, &node), "add");
    RSS(ref_layer_normal(ref_layer, ref_grid,
                         ref_node_global(layer_node, local), norm),
        "normal");
    for (i = 0; i < 3; i++)
      ref_node_xyz(layer_node, i, node) =
          0.1 * norm[i] + ref_node_xyz(layer_node, i, local);
  }

  /* layer of prisms */
  each_ref_list_item(ref_layer_list(ref_layer), item) {
    cell = ref_list_value(ref_layer_list(ref_layer), item);
    RSS(ref_cell_nodes(ref_cell, cell, nodes), "nodes");
    each_ref_cell_cell_node(ref_cell, cell_node) {
      RSS(ref_node_local(layer_node, nodes[cell_node], &local), "local");
      prism[cell_node] = local;
      prism[3 + cell_node] = local + nnode_per_layer;
    }
    RSS(ref_cell_add(layer_prism, prism, &new_cell), "add");
  }

  /* constrain faces */
  each_ref_list_item(ref_layer_list(ref_layer), item) {
    cell = ref_list_value(ref_layer_list(ref_layer), item);
    RSS(ref_cell_nodes(ref_cell, cell, nodes), "nodes");
    each_ref_cell_cell_edge(ref_cell, cell_edge) {
      REF_INT node0;
      REF_INT node1;
      REF_INT ncell, cell_list[2];
      REF_BOOL contains0, contains1;
      REF_INT edge_nodes[REF_CELL_MAX_SIZE_PER];
      node0 = nodes[ref_cell_e2n_gen(ref_cell, 0, cell_edge)];
      node1 = nodes[ref_cell_e2n_gen(ref_cell, 1, cell_edge)];
      RSS(ref_cell_list_with2(ref_cell, node0, node1, 2, &ncell, cell_list),
          "find with 2");
      REIS(2, ncell, "expected two tri for tri side");
      RSS(ref_list_contains(ref_layer_list(ref_layer), cell_list[0],
                            &contains0),
          "0 in layer");
      RSS(ref_list_contains(ref_layer_list(ref_layer), cell_list[1],
                            &contains1),
          "1 in layer");
      if (contains0 && contains1) continue; /* tri side interior to layer */
      if (!contains0 && !contains1) THROW("tri side is not in layer");
      RSS(ref_node_local(layer_node, node0, &local), "local");
      edge_nodes[0] = local + nnode_per_layer;
      RSS(ref_node_local(layer_node, node1, &local), "local");
      edge_nodes[1] = local + nnode_per_layer;
      if (contains0) {
        REIS(cell, cell_list[0], "cell should be in layer");
        edge_nodes[2] = ref_cell_c2n(ref_cell, 3, cell_list[1]);
      }
      if (contains1) {
        REIS(cell, cell_list[1], "cell should be in layer");
        edge_nodes[2] = ref_cell_c2n(ref_cell, 3, cell_list[0]);
      }
      RSS(ref_cell_add(layer_edge, edge_nodes, &new_cell), "add");
    }
  }

  return REF_SUCCESS;
}

REF_STATUS ref_layer_insert(REF_LAYER ref_layer, REF_GRID ref_grid) {
  REF_CELL ref_cell = ref_grid_tet(ref_grid);
  REF_NODE ref_node = ref_grid_node(ref_grid);
  REF_NODE layer_node = ref_grid_node(ref_layer_grid(ref_layer));
  REF_INT nnode_per_layer, node, local, global;
  REF_INT nodes[REF_CELL_MAX_SIZE_PER], node0, node1, node2, node3;
  REF_INT tet, i, new_node;
  REF_DBL bary[4];
  REF_INT zeros;
  REF_DBL zero_tol = 1.0e-10;
  REF_BOOL has_support;

  nnode_per_layer = ref_layer->nnode_per_layer;

  for (node = 0; node < nnode_per_layer; node++) {
    global = ref_node_global(layer_node, node); /* base */
    tet = ref_adj_first(ref_cell_adj(ref_cell), global);
    local = node + nnode_per_layer; /* target */
    RSS(ref_grid_enclosing_tet(ref_grid, ref_node_xyz_ptr(layer_node, local),
                               &tet, bary),
        "enclosing tet");
    RSS(ref_cell_nodes(ref_cell, tet, nodes), "nodes");
    zeros = 0;
    for (i = 0; i < 4; i++)
      if (ABS(bary[i]) < zero_tol) zeros++;
    new_node = REF_EMPTY;
    switch (zeros) {
      case 2: /* split an edge */
        node0 = REF_EMPTY;
        node1 = REF_EMPTY;
        for (i = 0; i < 4; i++)
          if (ABS(bary[i]) >= zero_tol) {
            if (node0 == REF_EMPTY) {
              node0 = i;
              continue;
            }
            if (node1 == REF_EMPTY) {
              node1 = i;
              continue;
            }
            THROW("more non-zeros than nodes");
          }
        if (node0 == REF_EMPTY) THROW("non-zero node0 missing");
        if (node1 == REF_EMPTY) THROW("non-zero node1 missing");
        node0 = nodes[node0];
        node1 = nodes[node1];
        RSS(ref_geom_supported(ref_grid_geom(ref_grid), node1, &has_support),
            "got geom?");
        if (has_support) RSS(REF_IMPLEMENT, "add geometry handling");
        RSS(ref_geom_supported(ref_grid_geom(ref_grid), node0, &has_support),
            "got geom?");
        if (has_support) RSS(REF_IMPLEMENT, "add geometry handling");
        RSS(ref_node_next_global(ref_node, &global), "next global");
        RSS(ref_node_add(ref_node, global, &new_node), "new node");
        RSS(ref_node_interpolate_edge(ref_node, node0, node1, new_node),
            "interp new node");
        RSS(ref_geom_add_between(ref_grid, node0, node1, new_node),
            "geom new node");
        RSS(ref_geom_constrain(ref_grid, new_node), "geom constraint");
        RSS(ref_split_edge(ref_grid, node0, node1, new_node), "split");
        for (i = 0; i < 3; i++)
          ref_node_xyz(ref_node, i, new_node) =
              ref_node_xyz(layer_node, i, local);
        break;
      case 1: /* split a triangular face*/
        node0 = REF_EMPTY;
        for (i = 0; i < 4; i++)
          if (ABS(bary[i]) < zero_tol) {
            if (node0 == REF_EMPTY) {
              node0 = i;
              continue;
            }
            THROW("more zeros than nodes");
          }
        if (node0 == REF_EMPTY) THROW("non-zero node0 missing");
        node1 = ref_cell_f2n_gen(ref_cell, 0, node0);
        node2 = ref_cell_f2n_gen(ref_cell, 1, node0);
        node3 = ref_cell_f2n_gen(ref_cell, 2, node0);
        node1 = nodes[node1];
        node2 = nodes[node2];
        node3 = nodes[node3];
        RSS(ref_geom_supported(ref_grid_geom(ref_grid), node1, &has_support),
            "got geom?");
        if (has_support) RSS(REF_IMPLEMENT, "add geometry handling");
        RSS(ref_geom_supported(ref_grid_geom(ref_grid), node2, &has_support),
            "got geom?");
        if (has_support) RSS(REF_IMPLEMENT, "add geometry handling");
        RSS(ref_geom_supported(ref_grid_geom(ref_grid), node3, &has_support),
            "got geom?");
        if (has_support) RSS(REF_IMPLEMENT, "add geometry handling");
        RSS(ref_node_next_global(ref_node, &global), "next global");
        RSS(ref_node_add(ref_node, global, &new_node), "new node");
        RSS(ref_node_interpolate_face(ref_node, node1, node2, node3, new_node),
            "interp new node");
        for (i = 0; i < 3; i++)
          ref_node_xyz(ref_node, i, new_node) =
              ref_node_xyz(layer_node, i, local);
        RSS(ref_split_face(ref_grid, node1, node2, node3, new_node), "fsplit");
        if (ref_layer->verbose)
          printf("split zeros %d bary %f %f %f %f\n", zeros, bary[0], bary[1],
                 bary[2], bary[3]);
        break;
      default:
        if (ref_layer->verbose)
          printf("implement zeros %d bary %f %f %f %f\n", zeros, bary[0],
                 bary[1], bary[2], bary[3]);
        RSS(REF_IMPLEMENT, "missing a general case");
        break;
    }
    RAS(REF_EMPTY != new_node, "new_node not set");
    layer_node->global[local] = new_node;

    if (ref_layer->verbose) RSS(ref_validation_cell_volume(ref_grid), "vol");
  }

  RSS(ref_node_rebuild_sorted_global(layer_node), "rebuild");

  return REF_SUCCESS;
}

REF_STATUS ref_layer_recon(REF_LAYER ref_layer, REF_GRID ref_grid) {
  REF_CELL ref_cell = ref_grid_tet(ref_grid);
  REF_NODE layer_node = ref_grid_node(ref_layer_grid(ref_layer));
  REF_CELL layer_edge = ref_grid_edg(ref_layer_grid(ref_layer));
  REF_INT cell, nodes[REF_CELL_MAX_SIZE_PER];
  REF_BOOL has_side;
  REF_INT node0, node1;

  each_ref_cell_valid_cell_with_nodes(layer_edge, cell, nodes) {
    node0 = ref_node_global(layer_node, nodes[0]);
    node1 = ref_node_global(layer_node, nodes[1]);
    RSS(ref_cell_has_side(ref_cell, node0, node1, &has_side), "side?");
    if (has_side) {
      if (ref_layer->verbose) printf("got one\n");
    } else {
      if (ref_layer->verbose) printf("need one\n");
    }
  }

  return REF_SUCCESS;
}
