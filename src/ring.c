
/* Ring, continuous loop of linear segements on a geometry face that
 *       is meshed by filling with triangles.
 *
 * Michael A. Park
 * Computational AeroSciences Branch
 * NASA Langley Research Center
 * Phone: (757) 864-6604
 * Email: Mike.Park@NASA.Gov
 */

/* $Id$ */

#include <stdlib.h>
#ifndef __APPLE__       /* Not needed on Mac OS X */
#include <malloc.h>
#endif
#include "ring.h"
#include "sort.h"

Ring* ringCreate( void )
{
  Ring *ring;

  ring = (Ring *)malloc( sizeof(Ring) );

  ring->malloc_chunk_size = 100;

  ring->segments = 0;
  ring->malloced_segments = 100;
  ring->segment_nodes = (int *)malloc(ring->malloced_segments*2*sizeof(int));
  ring->segment_uvs = 
    (double *)malloc(ring->malloced_segments*4*sizeof(double));

  ring->triangles = 0;

  return ring;
}

void ringFree( Ring *ring )
{
  if ( NULL != ring->segment_nodes ) free( ring->segment_nodes );
  if ( NULL != ring->segment_uvs   ) free( ring->segment_uvs );
  free( ring );
}

int ringSegments( Ring *ring )
{
  return ring->segments;
}

Ring *ringAddSegment( Ring *ring,
		      int node0, int node1,
		      double *uv0, double *uv1 )
{
  int segment;
  int remove_segment;

  for ( segment = 0 ; segment < ringSegments(ring) ; segment++ ) {
    if ( ring->segment_nodes[0+2*segment] == node0 &&
	 ring->segment_nodes[1+2*segment] == node1 ) {
      return NULL;
    }
  }

  remove_segment = EMPTY;
  for ( segment = 0 ;
	EMPTY == remove_segment && segment < ringSegments(ring) ;
	segment++ ) {
    if ( ring->segment_nodes[0+2*segment] == node1 &&
	 ring->segment_nodes[1+2*segment] == node0 ) {
      remove_segment = segment;
    }
  }

  if ( EMPTY != remove_segment ) {
    for ( segment = remove_segment ; 
	  segment < ( ringSegments(ring) - 1 ) ; 
	  segment++ ) {
      ring->segment_nodes[0+2*segment] = ring->segment_nodes[0+2*(segment+1)];
      ring->segment_nodes[1+2*segment] = ring->segment_nodes[1+2*(segment+1)];
      ring->segment_uvs[0+4*segment] = ring->segment_uvs[0+4*(segment+1)]; 
      ring->segment_uvs[1+4*segment] = ring->segment_uvs[1+4*(segment+1)]; 
      ring->segment_uvs[2+4*segment] = ring->segment_uvs[2+4*(segment+1)]; 
      ring->segment_uvs[3+4*segment] = ring->segment_uvs[3+4*(segment+1)]; 
    }
    ring->segments--;
    return ring;
  }

  if ( ring->segments >= ring->malloced_segments ) {
    ring->malloced_segments += ring->malloc_chunk_size;
    
    ring->segment_nodes = (int *)realloc(ring->segment_nodes,
					 ring->malloced_segments*2*sizeof(int));
    ring->segment_uvs =
      (double *)realloc(ring->segment_uvs,
			ring->malloced_segments*4*sizeof(double));
  }

  ring->segment_nodes[0+2*ring->segments] = node0;
  ring->segment_nodes[1+2*ring->segments] = node1;
  ring->segment_uvs[0+4*ring->segments] = uv0[0];
  ring->segment_uvs[1+4*ring->segments] = uv0[1];
  ring->segment_uvs[2+4*ring->segments] = uv1[0];
  ring->segment_uvs[3+4*ring->segments] = uv1[1];

  ring->segments++;
  return ring;
}

Ring *ringSegment( Ring *ring, int segment, int *node0, int *node1,
		   double *uv0, double *uv1 )
{
  if ( segment < 0 || segment >= ringSegments( ring ) ) return NULL;

  (*node0) = ring->segment_nodes[0+2*segment];
  (*node1) = ring->segment_nodes[1+2*segment];

  uv0[0] = ring->segment_uvs[0+4*segment];
  uv0[1] = ring->segment_uvs[1+4*segment];

  uv1[0] = ring->segment_uvs[2+4*segment];
  uv1[1] = ring->segment_uvs[3+4*segment];

  return ring;
}

int ringTriangles( Ring *ring )
{
  return ring->triangles;
}

Ring *ringAddTriangle( Ring *ring,
		       int node0, int node1, int node2,
		       double *uv2 )
{
  int segment;
  double uv0[2], uv1[2];
  for ( segment = 0 ; segment < ringSegments(ring) ; segment++ ) {
    if ( ring->segment_nodes[0+2*segment] == node0 &&
	 ring->segment_nodes[1+2*segment] == node1 ) {

      uv0[0] = ring->segment_uvs[0+4*segment];
      uv0[1] = ring->segment_uvs[1+4*segment];
      uv1[0] = ring->segment_uvs[2+4*segment];
      uv1[1] = ring->segment_uvs[3+4*segment];
      
      if ( ring != ringAddSegment(ring,node1,node0,uv1,uv0) ) {
	printf("%s: %d: ringAddTriangle: ringAddSegment 1 0 returned NULL.\n",
	       __FILE__,__LINE__);
	return NULL;
      }

      if ( ring != ringAddSegment(ring,node2,node1,uv2,uv1) ) {
	printf("%s: %d: ringAddTriangle: ringAddSegment 2 1 returned NULL.\n",
	       __FILE__,__LINE__);
	return NULL;
      }

      if ( ring != ringAddSegment(ring,node0,node2,uv1,uv2) ) {
	printf("%s: %d: ringAddTriangle: ringAddSegment 0 2 returned NULL.\n",
	       __FILE__,__LINE__);
	return NULL;
      }

      ring->triangles++;
      return ring;
    }
  }
  return NULL;
}

