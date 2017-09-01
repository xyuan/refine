#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "ref_fixture.h"

#include "ref_export.h"

#include "ref_adj.h"
#include "ref_grid.h"
#include "ref_cell.h"
#include "ref_node.h"
#include "ref_list.h"
#include "ref_matrix.h"

#include "ref_sort.h"
#include "ref_dict.h"
#include "ref_face.h"
#include "ref_mpi.h"

#include "ref_migrate.h"
#include "ref_validation.h"
#include "ref_edge.h"

#include "ref_metric.h"

int main( int argc, char *argv[] )
{

  RSS( ref_mpi_start( argc, argv ), "start" );

  if( REF_FALSE )
    { /* export for viz */
    REF_GRID ref_grid;

    RSS( ref_fixture_twod_brick_grid( &ref_grid ), "fix" );

    RSS( ref_validation_cell_node( ref_grid ), "invalid pri" );

    RSS( ref_export_tec( ref_grid, "twod.tec" ), "tec" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  {
    REF_GRID ref_grid;

    RSS( ref_fixture_pri_grid( &ref_grid ), "fix" );

    RSS( ref_validation_cell_node( ref_grid ), "invalid pri" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  {
    REF_GRID ref_grid;

    RSS( ref_fixture_tet2_grid( &ref_grid ), "fix" );

    RSS( ref_validation_cell_node( ref_grid ), "invalid pri" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  {
    REF_GRID ref_grid;
    REF_INT nodes[REF_CELL_MAX_SIZE_PER];
    REF_BOOL valid;

    RSS( ref_fixture_pri_grid( &ref_grid ), "fix" );
    
    RSS( ref_cell_nodes( ref_grid_tri(ref_grid), 0, nodes), "tri0");
    RSS(ref_node_tri_twod_orientation(ref_grid_node(ref_grid), 
				      nodes, &valid), "valid");
    RAS( valid, "expected valid" );
    RSS( ref_cell_nodes( ref_grid_tri(ref_grid), 1, nodes), "tri0");
    RSS(ref_node_tri_twod_orientation(ref_grid_node(ref_grid),
				      nodes, &valid), "valid");
    RAS( valid, "expected valid" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  {
    REF_GRID ref_grid;

    RSS( ref_fixture_pri_stack_grid( &ref_grid ), "fix" );

    if ( 1 < ref_mpi_n ) 
      RSS( ref_export_tec_part( ref_grid, "ref_fixture_orig_stack" ), "see" );

    RSS( ref_validation_cell_node( ref_grid ), "invalid stack" );

    RSS( ref_migrate_to_balance( ref_grid ), "bal" );

    if ( 1 < ref_mpi_n ) 
      RSS( ref_export_tec_part( ref_grid, "ref_fixture_bal_stack" ), "see" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  {
    REF_GRID ref_grid;

    RSS( ref_fixture_pri_grid( &ref_grid ), "fix" );

    if ( 1 < ref_mpi_n ) 
      RSS( ref_export_tec_part( ref_grid, "ref_fixture_orig_pri" ), "see" );

    RSS( ref_validation_cell_node( ref_grid ), "invalid pri" );

    RSS( ref_migrate_to_balance( ref_grid ), "bal" );

    if ( 1 < ref_mpi_n ) 
      RSS( ref_export_tec_part( ref_grid, "ref_fixture_bal_pri" ), "see" );

    RSS( ref_grid_free(ref_grid),"free");
  }

  if ( 2 == argc )
    {
      REF_GRID ref_grid;
      RSS( ref_fixture_tet_brick_grid( &ref_grid ), "boom3d" );
      RSS( ref_export_by_extension( ref_grid, argv[1] ), "export" );
      RSS( ref_grid_free(ref_grid),"free");
    }

  if ( 3 == argc )
    {
      REF_GRID ref_grid;
      REF_INT dn;
      dn = atoi(argv[1]);
      RSS( ref_fixture_hex_brick_grid( &ref_grid, dn ), "boom3d" );
      RSS( ref_export_by_extension( ref_grid, argv[2] ), "export" );
      RSS( ref_grid_free(ref_grid),"free");
    }

  if ( 5 == argc )
    {
      REF_GRID ref_grid;
      REF_INT nx = atoi(argv[1]);
      REF_INT nz = atoi(argv[2]);
      REF_DBL rot_deg  = atof(argv[3]);
      RSS( ref_fixture_boom2d_grid( &ref_grid, 
				    nx, nz, rot_deg  ), "boom3d" );
      RSS( ref_export_by_extension( ref_grid, argv[4] ), "export" );
      RSS( ref_grid_free(ref_grid),"free");
    }

  if ( 6 == argc )
    {
      REF_GRID ref_grid;
      REF_INT nx = atoi(argv[1]);
      REF_INT nt = atoi(argv[2]);
      REF_INT nr = atoi(argv[3]);
      REF_DBL rot_deg  = atof(argv[4]);
      RSS( ref_fixture_boom3d_grid( &ref_grid, 
				    nx, nt, nr, rot_deg  ), "boom3d" );
      RSS( ref_export_by_extension( ref_grid, argv[5] ), "export" );
      RSS( ref_grid_free(ref_grid),"free");
    }

  RSS( ref_mpi_stop( ), "stop" );

  return 0;
}