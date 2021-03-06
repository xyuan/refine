#!/usr/bin/env ruby
#

#
# Mobility test for layer c lib

Dir.chdir ENV['srcdir'] if ENV['srcdir']
$:.push "." # ruby 1.9.2
require 'RubyExtensionBuilder'
RubyExtensionBuilder.new('GridMove').build

require 'test/unit'
require 'Adj/Adj'
require 'Line/Line'
require 'Grid/Grid'
require 'GridMath/GridMath'
require 'GridMetric/GridMetric'
require 'GridMove/GridMove'

class Grid
 include GridMetric
end

class TestGridMove < Test::Unit::TestCase

 EMPTY = (-1)
 
 def isoTet
  grid = Grid.new(4,1,4,0)
  grid.addNode(0,0,0)
  grid.addNode(1,0,0)
  grid.addNode(0.5,0.866,0)
  grid.addNode(0.5,0.35,0.8)
  grid.addCell(0,1,2,3)
  grid.addFace(0,1,2,10)
  grid.addFace(0,3,1,10)
  grid.addFace(1,3,2,10)
  grid.addFace(0,2,3,10)
  grid
 end

 def testSpecifiedDisplacement
  grid = isoTet
  assert_not_nil gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up   = [0.0,0.0,1.0]
  assert_nil gm.displacement(-1)
  assert_nil gm.displacement(4)
  assert_equal false, gm.specified(-1)
  assert_equal false, gm.specified(4)
  assert_equal false, gm.specified(0)
  assert_equal zero,  gm.displacement(0)
  assert_equal gm,    gm.displace(0,up)
  assert_equal true,  gm.specified(0)
  assert_equal up,    gm.displacement(0)
 end

 def testInitGC
  grid = isoTet
  gm = GridMove.new(grid)

  assert_not_nil  grid = String.new("hello")
  assert_nil      GC.start

  assert_nil gm.displacement(-1)
  assert_nil gm.displacement(4)
  zero = [0.0,0.0,0.0]
  assert_equal zero, gm.displacement(0)
 end

 def testNodeRealloc
  grid = Grid.new(1,0,0,0)
  grid.addNode(0.0,0.0,0.0)
  gm = GridMove.new(grid)
  1000.times{grid.addNode(0.0,0.0,0.0)}

  zero = [0.0,0.0,0.0]
  assert_equal false, gm.specified(1000)
  assert_equal zero,  gm.displacement(1000)
 end

 def testNodePack
  grid = Grid.new(4,0,0,0)
  4.times { grid.addNode(0.0,0.0,0.0) }
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  d = [1.1,2.2,3.3]
  assert_equal gm, gm.displace(3,d)
  grid.removeNode(0)
  grid.pack
  assert_equal false, gm.specified(3)
  assert_equal zero,  gm.displacement(3)
  assert_equal true,  gm.specified(2)
  assert_equal d,     gm.displacement(2)
 end

 def testSprings
  grid = Grid.new(5,2,0,0)
  gm = GridMove.new(grid)
  5.times { grid.addNode(0.0,0.0,0.0) }
  grid.addCell(0,1,2,3)
  assert_equal [0,1, 0,2, 0,3, 1,2, 1,3, 2,3], gm.springs  
  grid.addCell(1,0,2,4)
  assert_equal [0,1, 0,2, 0,3, 1,2, 1,3, 2,3, 1,4, 0,4, 2,4], gm.springs  
 end

 def testSpringRelaxationUp
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  3.times{|n| gm.displace(n,up)}
  assert_equal zero, gm.displacement(3)
  assert_equal gm, gm.springRelaxation(1,1)
  assert_equal up, gm.displacement(0)
  assert_equal up, gm.displacement(1)
  assert_equal up, gm.displacement(2)
  delta = 1.0e-15
  assert_in_delta up[0], gm.displacement(3)[0], delta
  assert_in_delta up[1], gm.displacement(3)[1], delta
  assert_in_delta up[2], gm.displacement(3)[2], delta
 end

 def testSpringRelaxationUpSteps
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  3.times{|n| gm.displace(n,up)}
  assert_equal zero, gm.displacement(3)
  assert_equal gm, gm.springRelaxation(10,1)
  assert_equal up, gm.displacement(0)
  assert_equal up, gm.displacement(1)
  assert_equal up, gm.displacement(2)
  delta = 1.0e-15
  assert_in_delta up[0], gm.displacement(3)[0], delta
  assert_in_delta up[1], gm.displacement(3)[1], delta
  assert_in_delta up[2], gm.displacement(3)[2], delta
 end

 def testSpringRelaxationUpSubiters
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  3.times{|n| gm.displace(n,up)}
  assert_equal zero, gm.displacement(3)
  assert_equal gm, gm.springRelaxation(1,10)
  assert_equal up, gm.displacement(0)
  assert_equal up, gm.displacement(1)
  assert_equal up, gm.displacement(2)
  delta = 1.0e-15
  assert_in_delta up[0], gm.displacement(3)[0], delta
  assert_in_delta up[1], gm.displacement(3)[1], delta
  assert_in_delta up[2], gm.displacement(3)[2], delta
 end

 def isoTet4 h 
  grid = Grid.new(5,4,4,0)
  grid.addNode(0,0,0)
  grid.addNode(1,0,0)
  grid.addNode(0.5,0.866,0)
  grid.addNode(0.5,0.35,0.8)
  grid.addNode(0.5,0.35,0.8*h)

  grid.addCell(0,1,2,4)
  grid.addCell(0,3,1,4)
  grid.addCell(1,3,2,4)
  grid.addCell(0,2,3,4)

  grid.addFace(0,1,2,10)
  grid.addFace(0,3,1,10)
  grid.addFace(1,3,2,10)
  grid.addFace(0,2,3,10)
  grid
 end

 def testSpringRelaxationSqwish
  h = 0.1
  grid = isoTet4 h
  gm = GridMove.new(grid)
  3.times{|n| gm.displace(n,[0.0,0.0,0.0])}
  gm.displace(3,[0.0,0.0,-0.78])
  gm.springRelaxation(1,1)
  gm.applyDisplacements
  minVol = grid.minVolume
  assert(1.0e-12<minVol,"negative volume of #{minVol}")
 end

 def testApplyDisplacement
  grid = Grid.new(2,0,0,0)
  grid.addNode(0,0,0)
  grid.addNode(0,1,0)
  gm = GridMove.new(grid)
  gm.displace(0,[0,0,1])
  assert_equal gm, gm.applyDisplacements
  assert_equal [0,0,1], grid.nodeXYZ(0)
  assert_equal [0,1,0], grid.nodeXYZ(1)
 end
 
 def testCellFaceNormals
  grid = isoTet
  gm = GridMove.new(grid)
  xyz=[grid.nodeXYZ(0),grid.nodeXYZ(1),grid.nodeXYZ(2),grid.nodeXYZ(3)].flatten
  assert_equal [0,0,1], gm.cellFaceNormal(xyz,[0,1,2,3],0)
  assert_equal [0,0,1], gm.cellFaceNormal(xyz,[1,0,3,2],1)
  assert_equal [0,0,1], gm.cellFaceNormal(xyz,[3,2,1,0],2)
  assert_equal [0,0,1], gm.cellFaceNormal(xyz,[2,3,0,1],3)
 end

 def testCompRowOneCell
  grid = Grid.new(5,2,0,0)
  gm = GridMove.new(grid)
  5.times { grid.addNode(0.0,0.0,0.0) }
  grid.addCell(0,1,2,3)
  assert_equal EMPTY, gm.rowStart(EMPTY)
  assert_equal  0,    gm.rowStart(0)
  assert_equal  4,    gm.rowStart(1)
  assert_equal  8,    gm.rowStart(2)
  assert_equal 12,    gm.rowStart(3)
  assert_equal 16,    gm.rowStart(4)
  assert_equal 16,    gm.rowStart(5)
  assert_equal EMPTY, gm.rowStart(6)
  assert_equal 16, gm.nnz
  assert_nil              gm.rowNodes(EMPTY)
  assert_equal [0,1,2,3], gm.rowNodes(0)
  assert_equal [0,1,2,3], gm.rowNodes(1)
  assert_equal [0,1,2,3], gm.rowNodes(2)
  assert_equal [0,1,2,3], gm.rowNodes(3)
  assert_equal [],        gm.rowNodes(4)
 end

 def testCompRowTwoCells
  grid = Grid.new(6,2,0,0)
  gm = GridMove.new(grid)
  6.times { grid.addNode(0.0,0.0,0.0) }
  grid.addCell(0,1,2,3)
  grid.addCell(1,0,2,4)
  assert_equal EMPTY, gm.rowStart(EMPTY)
  assert_equal  0,    gm.rowStart(0)
  assert_equal  5,    gm.rowStart(1)
  assert_equal 10,    gm.rowStart(2)
  assert_equal 15,    gm.rowStart(3)
  assert_equal 19,    gm.rowStart(4)
  assert_equal 23,    gm.rowStart(5)
  assert_equal 23,    gm.rowStart(6)
  assert_equal EMPTY, gm.rowStart(7)
  assert_equal 23, gm.nnz
  assert_nil              gm.rowNodes(EMPTY)
  assert_equal [0,1,2,3,4], gm.rowNodes(0)
  assert_equal [0,1,2,3,4], gm.rowNodes(1)
  assert_equal [0,1,2,3,4], gm.rowNodes(2)
  assert_equal [0,1,2,3], gm.rowNodes(3)
  assert_equal [0,1,2,4], gm.rowNodes(4)
  assert_equal [],        gm.rowNodes(5)
 end

 def testCompRowOneCellFindEntry
  grid = Grid.new(5,2,0,0)
  gm = GridMove.new(grid)
  5.times { grid.addNode(0.0,0.0,0.0) }
  grid.addCell(0,1,2,3)
  assert_equal EMPTY, gm.rowEntry(EMPTY,EMPTY)
  assert_equal EMPTY, gm.rowEntry(0,EMPTY)
  assert_equal EMPTY, gm.rowEntry(0,4)
  assert_equal EMPTY, gm.rowEntry(4,4)

  assert_equal  0,    gm.rowEntry(0,0)
  assert_equal  5,    gm.rowEntry(1,1)
  assert_equal 10,    gm.rowEntry(2,2)
  assert_equal 15,    gm.rowEntry(3,3)

  assert_equal  1,    gm.rowEntry(0,1)
  assert_equal  2,    gm.rowEntry(0,2)
  assert_equal  3,    gm.rowEntry(0,3)

  assert_equal  4,    gm.rowEntry(1,0)
  assert_equal  6,    gm.rowEntry(1,2)
  assert_equal  7,    gm.rowEntry(1,3)
 end

 def XtestElasticityOneCellDumpA
  grid = isoTet
  gm = GridMove.new(grid)
  assert_equal gm, gm.elasticRelaxationDumpA
 end

 def testElasticRelaxationUp3
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  3.times{|n| gm.displace(n,up)}
  assert_equal zero, gm.displacement(3)
  assert_equal gm, gm.elasticRelaxation(1,1)
  assert_equal up, gm.displacement(0)
  assert_equal up, gm.displacement(1)
  assert_equal up, gm.displacement(2)
  delta = 1.0e-14
  assert_in_delta up[0], gm.displacement(3)[0], delta
  assert_in_delta up[1], gm.displacement(3)[1], delta
  assert_in_delta up[2], gm.displacement(3)[2], delta
 end

 def testElasticRelaxationUp0
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  gm.displace(1,up)
  gm.displace(2,up)
  gm.displace(3,up)
  assert_equal gm, gm.elasticRelaxation(1,1)
  n = 0
  delta = 1.0e-14
  assert_in_delta up[0], gm.displacement(n)[0], delta
  assert_in_delta up[1], gm.displacement(n)[1], delta
  assert_in_delta up[2], gm.displacement(n)[2], delta
 end

 def testElasticRelaxationUp1
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  gm.displace(0,up)
  gm.displace(2,up)
  gm.displace(3,up)
  assert_equal gm, gm.elasticRelaxation(1,1)
  n = 1
  delta = 1.0e-14
  assert_in_delta up[0], gm.displacement(n)[0], delta
  assert_in_delta up[1], gm.displacement(n)[1], delta
  assert_in_delta up[2], gm.displacement(n)[2], delta
 end

 def testElasticRelaxationUp2
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  gm.displace(0,up)
  gm.displace(1,up)
  gm.displace(3,up)
  assert_equal gm, gm.elasticRelaxation(1,1)
  n = 2
  delta = 1.0e-14
  assert_in_delta up[0], gm.displacement(n)[0], delta
  assert_in_delta up[1], gm.displacement(n)[1], delta
  assert_in_delta up[2], gm.displacement(n)[2], delta
 end

 def testElasticRelaxationUpSteps
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,1.0]
  3.times{|n| gm.displace(n,up)}
  assert_equal zero, gm.displacement(3)
  assert_equal gm, gm.elasticRelaxation(10,1)
  assert_equal up, gm.displacement(0)
  assert_equal up, gm.displacement(1)
  assert_equal up, gm.displacement(2)
  delta = 1.0e-14
  assert_in_delta up[0], gm.displacement(3)[0], delta
  assert_in_delta up[1], gm.displacement(3)[1], delta
  assert_in_delta up[2], gm.displacement(3)[2], delta
 end

 def testElasticRelaxationSqwish
  h = 0.1
  grid = isoTet4 h
  gm = GridMove.new(grid)
  3.times{|n| gm.displace(n,[0.0,0.0,0.0])}
  gm.displace(3,[0.0,0.0,-0.74])
  gm.elasticRelaxation(3,1)
  gm.applyDisplacements
  minVol = grid.minVolume
  assert(1.0e-12<minVol,"negative volume of #{minVol}")
 end

 def testElasticRelaxationRotate3
  grid = isoTet
  gm = GridMove.new(grid)
  zero = [0.0,0.0,0.0]
  up  = [0.0,0.0,0.1]
  2.times{|n| gm.displace(n,zero)}
  gm.displace(2,up)
  assert_equal gm, gm.elasticRelaxation(1,1)
  ans = [0.0, -0.092486, 0.040415]
  ans = [0.0, -0.010264, 0.040415]
  ans = [0.0,  0.000000, 0.040415]
  delta = 1.0e-5
  assert_in_delta ans[0], gm.displacement(3)[0], delta
  assert_in_delta ans[1], gm.displacement(3)[1], delta
  assert_in_delta ans[2], gm.displacement(3)[2], delta
 end

end
