
/* Michael A. Park
 * Computational Modeling & Simulation Branch
 * NASA Langley Research Center
 * Phone:(757)864-6604
 * Email:m.a.park@larc.nasa.gov
 */

/* $Id$ */

#ifndef GRIDFORTRAN_H
#define GRIDFORTRAN_H

#include "master_header.h"

BEGIN_C_DECLORATION

int gridcreate_( int *nnode, double *x, double *y, double *z,
		 int *ncell, int *maxcell, int *c2n );

int gridinsertboundary_( int *faceId, double *nnode, double *inode, 
			 double *nface, double *ndim, int *f2n );

END_C_DECLORATION

#endif /* GRIDFORTRAN_H */
