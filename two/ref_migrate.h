
#ifndef REF_MIGRATE_H
#define REF_MIGRATE_H

#include "ref_defs.h"

#include "ref_grid.h"

BEGIN_C_DECLORATION

REF_STATUS ref_migrate_to_balance( REF_GRID ref_grid );

REF_STATUS ref_migrate_new_part( REF_GRID ref_grid );

REF_STATUS ref_migrate_shufflin( REF_GRID ref_grid );
REF_STATUS ref_migrate_shufflin_cell( REF_NODE ref_node, 
				      REF_CELL ref_cell );

END_C_DECLORATION

#endif /* REF_MIGRATE_H */
