#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "ref_inflate.h"

#include "ref_math.h"

#include "ref_import.h"
#include "ref_export.h"

#include "ref_cell.h"
#include "ref_grid.h"
#include "ref_sort.h"
#include "ref_adj.h"
#include "ref_node.h"
#include "ref_matrix.h"
#include "ref_mpi.h"
#include "ref_dict.h"
#include "ref_list.h"

#include "ref_edge.h"

#include "ref_fixture.h"
#include "ref_metric.h"
#include "ref_gather.h"

int main( int argc, char *argv[] )
{
  REF_GRID ref_grid;
  REF_NODE ref_node;
  
  if ( 3 == argc )
    {
      switch ( atoi(argv[1]) )
	{
	case 1:
	  RSS( ref_fixture_tet_brick_grid( &ref_grid ), "brick");
	  break;
	case 2:
	  RSS( ref_fixture_twod_brick_grid( &ref_grid ), "brick");
	  break;
	default:
	  THROW("case not recognized");
	  break;
	}
      RSS( ref_export_by_extension( ref_grid, argv[2] ), "out" );

      return 0;
    }

  if ( 4 == argc )
    {
      RSS( ref_import_by_extension( &ref_grid, argv[1] ), "in");

      RSS( ref_metric_olympic_node( ref_grid_node(ref_grid), atof(argv[3]) ),
	   "oly" );
      if (ref_grid_twod(ref_grid))
	RSS( ref_metric_twod_node( ref_grid_node(ref_grid) ), "2d" );

      RSS( ref_gather_metric( ref_grid, argv[2] ), "in");

      return 0;
    }

  if ( 5 == argc )
    {
      REF_DBL x, z, h, c, r, k;
      REF_INT node;

      c = atof(argv[3]);
      k = atof(argv[4]);

      RSS( ref_import_by_extension( &ref_grid, argv[1] ), "in");
      ref_node = ref_grid_node(ref_grid);

      each_ref_node_valid_node( ref_node, node )
      {
	x = ref_node_xyz(ref_node,0,node);
	z = ref_node_xyz(ref_node,2,node);
	r = sqrt( x*x + z*z );
	r = MAX( r, 0.02*c*c );
	h = c * pow(r,k); 
 
	ref_node_metric(ref_node,0,node) = 1.0/(h*h);
	ref_node_metric(ref_node,1,node) = 0.0;
	ref_node_metric(ref_node,2,node) = 0.0;
	ref_node_metric(ref_node,3,node) = 1.0;
	ref_node_metric(ref_node,4,node) = 0.0;
	ref_node_metric(ref_node,5,node) = 1.0/(h*h);
      } 

      if (ref_grid_twod(ref_grid))
	RSS( ref_metric_twod_node( ref_grid_node(ref_grid) ), "2d" );

      RSS( ref_gather_metric( ref_grid, argv[2] ), "in");

      return 0;
    }

  return 0;
}
