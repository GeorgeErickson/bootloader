require './test_helper'
bootloader = require('../')

describe 'bootloader', ->
  it 'Loads stuff in order', (done) ->
    bootloader './test/example', (data) ->

      expect(data).to.deep.equal
        dep_1: 1
        dep_2: 2
        dep_3: 3
      done()
