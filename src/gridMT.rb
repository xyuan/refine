#!/usr/bin/env ruby
#
# $Id$
#
# Mobility test for grid c lib

exit unless system 'ruby extconf.rb Grid adj.c'
exit unless system 'make'

require 'test/unit'
require 'Grid'

class Grid
 def totalVolume
  vol = 0.0
  ncell.times { |cellId| vol += volume(cell(cellId)) }
  vol
 end
end

class TestSampleUnit < Test::Unit::TestCase

 def set_up
  @grid = Grid.new(4,1,0)
 end

 def testCreateGrid
  assert_equal 4, @grid.maxnode
  assert_equal 0, @grid.nnode
  assert_equal 1, @grid.maxcell
  assert_equal 0, @grid.ncell
 end

 def testAddCellDegAndCell
  assert_equal 0, @grid.ncell
  assert_equal nil, @grid.cell(0)
  assert_equal nil, @grid.cell(5)
  assert_equal @grid, @grid.addCell(0,1,2,3)
  assert_equal [0, 1, 2, 3], @grid.cell(0)
  assert_equal 1, @grid.ncell
  (0..3).each { |n| assert_equal 1, @grid.cellDegree(n)}
 end

 def testAddCellRegFailure
  grid = Grid.new(3,1,0)
  assert_equal nil, grid.addCell(0,1,2,3)
  grid = Grid.new(4,1,0)
  assert_equal grid, grid.addCell(0,1,2,3)
  assert_equal nil, grid.addCell(0,1,2,3)
 end
 
 def testRemoveCell
  assert_equal @grid, @grid.addCell(0,1,2,3)
  assert_equal nil, @grid.removeCell(25625)
  assert_equal 1, @grid.ncell
  assert_equal @grid, @grid.removeCell(0)
  assert_equal nil, @grid.cell(0)
  assert_equal nil, @grid.removeCell(0)
  assert_equal 0, @grid.ncell
  (0..3).each { |n| assert_equal 0, @grid.cellDegree(n)}
 end

 def testReplaceCell
  grid = Grid.new(8,2,0)
  assert_equal grid, grid.addCell(0,1,2,3).addCell(4,5,6,7)
  assert_equal grid, grid.removeCell(0)
  assert_equal grid, grid.addCell(0,1,2,3)
  assert_equal [0, 1, 2, 3], grid.cell(0)
  assert_equal [4, 5, 6, 7], grid.cell(1)
 end

 def testGetGem
  grid = Grid.new(5,3,0)
  assert_equal grid, grid.addCell(3,4,0,1).addCell(3,4,1,2).addCell(3,4,2,0)
  assert_equal [], grid.gem(5,6)
  assert_equal [0], grid.gem(0,1)
  assert_equal [1], grid.gem(1,2)
  assert_equal [2], grid.gem(0,2)
  assert_equal [2,0], grid.gem(3,0)
  assert_equal [2,1,0], grid.gem(3,4)
 end
 
  def testOrient
  assert_equal nil, @grid.orient(0,1,2,3,4,5)
  
  assert_equal [0, 1, 2, 3], @grid.orient(0,1,2,3,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(0,3,1,2,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(0,2,3,1,0,1)

  assert_equal [0, 1, 2, 3], @grid.orient(1,0,3,2,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(1,2,0,3,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(1,3,2,0,0,1)

  assert_equal [0, 1, 2, 3], @grid.orient(2,3,0,1,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(2,1,3,0,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(2,0,1,3,0,1)

  assert_equal [0, 1, 2, 3], @grid.orient(3,2,1,0,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(3,0,2,1,0,1)
  assert_equal [0, 1, 2, 3], @grid.orient(3,1,0,2,0,1)
 end

 def testEquator
  grid = Grid.new(6,4,0)
  assert_equal grid, grid.
   addCell(4,5,1,2).addCell(4,5,2,3).addCell(4,5,3,0).addCell(4,5,0,1)
  assert_equal [3,2,1,0], grid.gem(4,5)
  assert_equal 2, grid.cellDegree(0)
  assert_equal 4, grid.cellDegree(5)
  assert_equal [], grid.equator(0,2)
  assert_equal [], grid.equator(6,7)
  assert_equal [1,2,3,0,1], grid.equator(4,5)
 end

 def testEquatorGapInMiddle
  grid = Grid.new(6,3,0)
  assert_equal grid, grid.addCell(4,5,1,2).addCell(4,5,2,3)
  assert_equal [1,0], grid.gem(4,5)
  assert_equal [1,2,3,1], grid.equator(4,5)
 end

 def testEquatorGapInEnd
  grid = Grid.new(6,3,0)
  assert_equal grid, grid.addCell(4,5,1,2).addCell(4,5,3,1)
  assert_equal [3,1,2,3], grid.equator(4,5)
 end

 def testEquatorTwoGaps
  grid = Grid.new(6,3,0)
  assert_equal grid, grid.addCell(4,5,1,2).addCell(4,5,3,0)
  assert_equal nil, grid.equator(4,5)
 end

 def testAddNode
  grid = Grid.new(1,1,0)
  assert_equal 0, grid.addNode(1.0,0.0,0.0)
  assert_equal( -1, grid.addNode(1.0,0.0,0.0))
 end

 def testMetrics
  assert_equal @grid, @grid.
   addCell( @grid.addNode(0.0,0.0,0.0), @grid.addNode(1.0,0.0,0.0), 
	    @grid.addNode(0.0,1.0,0.0), @grid.addNode(0.0,0.0,1.0) )
  nodes = [0,1,2,3]
  assert_in_delta 1.0/6.0, @grid.volume(nodes), 1.0e-15
  assert_in_delta 1.0/6.0, @grid.minVolume, 1.0e-15
  assert_in_delta 0.732050807568877, @grid.ar(nodes), 1.0e-15
 end

 def testSwap4_0
  assert_not_nil grid=gemGrid(4, 0.1, 0)
  initalVolume = grid.totalVolume
  grid.swap(0,1)
  assert grid.minVolume>0.0, "negative volume cell "+grid.minVolume.to_s
  assert_in_delta initalVolume, grid.totalVolume, 1.0e-15
  assert_equal 2, grid.cellDegree(0)
  assert_equal 2, grid.cellDegree(1)
  assert_equal 4, grid.cellDegree(2)
  assert_equal 2, grid.cellDegree(3)
  assert_equal 4, grid.cellDegree(4)
  assert_equal 2, grid.cellDegree(5)
 end

 def testSwap4_1
  assert_not_nil grid=gemGrid(4, 0.1, 1)
  initalVolume = grid.totalVolume
  grid.swap(0,1)
  assert grid.minVolume>0.0, "negative volume cell "+grid.minVolume.to_s
  assert_in_delta initalVolume, grid.totalVolume, 1.0e-15
  assert_equal 2, grid.cellDegree(0)
  assert_equal 2, grid.cellDegree(1)
  assert_equal 2, grid.cellDegree(2)
  assert_equal 4, grid.cellDegree(3)
  assert_equal 2, grid.cellDegree(4)
  assert_equal 4, grid.cellDegree(5)
 end

 def testSwap4_invalid
  assert_not_nil grid=gemGrid(4, 0.1, nil, -0.1)
  grid.swap(0,1)
  assert_equal 4, grid.cellDegree(0)
  assert_equal 4, grid.cellDegree(1)
 end

# put faces in

 def testFace
  assert_equal 0, @grid.nface 
  assert_equal 0, @grid.maxface 
  assert_not_nil  grid = Grid.new(4,1,2)
  assert_equal 0, grid.nface 
  assert_equal 2, grid.maxface 

  assert_not_nil    grid.addFace(0, 1, 2, 10)
  assert_equal 1,   grid.nface 
  assert_equal 10,  grid.faceId( 0, 1, 2 )
  assert_equal 10,  grid.faceId( 1, 2, 0 )
  assert_equal 10,  grid.faceId( 2, 0, 1 )
  assert_equal 10,  grid.faceId( 2, 1, 0 )
  assert_equal( -1, grid.faceId( 1, 2, 3 ) )

  assert_not_nil   grid.addFace(3, 1, 2, 11)
  assert_equal 10, grid.faceId( 0, 1, 2 )
  assert_equal 11, grid.faceId( 1, 2, 3 )
  assert_nil       grid.addFace(0, 1, 2, 12)
 end

 def testSwap4_gapWithSameFaces
  assert_not_nil     grid=gemGrid(4, nil, nil, nil, true)
  assert_equal 3,    grid.ncell
  assert_equal grid, grid.addFace(0,1,2,11)
  assert_equal grid, grid.addFace(0,1,5,11)
  assert_equal grid, grid.swap(0,1)
  assert_equal 4,    grid.ncell
  assert_equal 2,    grid.cellDegree(0)
  assert_equal 2,    grid.cellDegree(1)
 end

 def testSwap4_gapWithDifferentFaces
  assert_not_nil     grid=gemGrid(4, nil, nil, nil, true)
  assert_equal 3,    grid.ncell
  assert_equal grid, grid.addFace(0,1,2,2)
  assert_equal grid, grid.addFace(0,1,5,5)
  assert_nil         grid.swap(0,1)
  assert_equal 3,    grid.ncell
  assert_equal 3,    grid.cellDegree(0)
  assert_equal 3,    grid.cellDegree(1)
 end

 def testSwap4_gapWithSameAndExistingFace0
  assert_not_nil     grid=gemGrid(4, nil, nil, nil, true)
  assert_equal 3,    grid.ncell
  assert_equal grid, grid.addFace(0,1,2,11)
  assert_equal grid, grid.addFace(0,1,5,11)
  assert_equal grid, grid.addFace(0,2,5,20)
  assert_nil         grid.swap(0,1)
  assert_equal 3,    grid.ncell
  assert_equal 3,    grid.cellDegree(0)
  assert_equal 3,    grid.cellDegree(1)
 end

 def testSwap4_gapWithSameAndExistingFace1
  assert_not_nil     grid=gemGrid(4, nil, nil, nil, true)
  assert_equal 3,    grid.ncell
  assert_equal grid, grid.addFace(0,1,2,11)
  assert_equal grid, grid.addFace(0,1,5,11)
  assert_equal grid, grid.addFace(1,2,5,20)
  assert_nil         grid.swap(0,1)
  assert_equal 3,    grid.ncell
  assert_equal 3,    grid.cellDegree(0)
  assert_equal 3,    grid.cellDegree(1)
 end

 def testSwap5_0
  assert_not_nil grid=gemGrid(5, 0.1, 0)
  initalVolume = grid.totalVolume
  grid.swap(0,1)
  assert grid.minVolume>0.0, "negative volume cell "+grid.minVolume.to_s
  assert_in_delta initalVolume, grid.totalVolume, 1.0e-15
  assert_equal 3, grid.cellDegree(0)
  assert_equal 3, grid.cellDegree(1)
  assert_equal 6, grid.cellDegree(2)
  assert_equal 2, grid.cellDegree(3)
  assert_equal 4, grid.cellDegree(4)
  assert_equal 4, grid.cellDegree(5)
  assert_equal 2, grid.cellDegree(6)
 end

 def testSwap5_1
  assert_not_nil grid=gemGrid(5, 0.1, 1)
  initalVolume = grid.totalVolume
  grid.swap(0,1)
  assert grid.minVolume>0.0, "negative volume cell "+grid.minVolume.to_s
  assert_in_delta initalVolume, grid.totalVolume, 1.0e-15
  assert_equal 3, grid.cellDegree(0)
  assert_equal 3, grid.cellDegree(1)
  assert_equal 2, grid.cellDegree(2)
  assert_equal 6, grid.cellDegree(3)
  assert_equal 2, grid.cellDegree(4)
  assert_equal 4, grid.cellDegree(5)
  assert_equal 4, grid.cellDegree(6)
 end

 def gemGrid(nequ=4, a=nil, dent=nil, x0 = nil, gap = nil)
  a  = a  || 0.1
  x0 = x0 || 1.0
  grid = Grid.new(nequ+2,14,14)
  n = Array.new
  n.push grid.addNode(x0,0.0,0.0)
  n.push grid.addNode(-1.0,0.0,0.0)
  nequ.times do |i| 
   angle = 2.0*Math::PI*(i-1)/(nequ)
   s = if (dent==i) then 0.9 else 1.0 end
   n.push grid.addNode(0.0,s*a*Math.sin(angle),s*a*Math.cos(angle)) 
  end
  n.push 2
  ngem = (gap)?(nequ-1):(nequ)
  ngem.times do |i|
   grid.addCell(n[0],n[1],n[i+2],n[i+3])
  end
  grid  
 end


 def XtestMaxSize
  nnode = 6000000
  grid = Grid.new(nnode,nnode*6,0)
  1.upto(nnode*6) {grid.addCell(3,4,0,1)}
 end


 # make register unique

 # allocating a new chunk of celllist

end
