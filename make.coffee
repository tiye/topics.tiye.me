#!/usr/bin/env coffee
project = 'topics.tiye.dev'

require 'shelljs/make'
path = require 'path'
mission = require 'mission'

mission.time()

target.folder = ->
  mission.tree
    '.gitignore': ''
    'README.md': ''
    js: {}
    build: {}
    cirru: {'index.cirru': ''}
    coffee: {'main.coffee': ''}
    css: {'style.css': ''}

target.coffee = ->
  mission.coffee
    find: /\.coffee$/, from: 'coffee/', to: 'js/', extname: '.js'
    options:
      bare: yes

cirru = ->
  mission.cirru
    file: 'index.cirru', from: 'cirru/', to: './', extname: '.html'

browserify = (callback) ->
  mission.browserify
    file: 'main.js', from: 'js/', to: 'build/', done: callback

target.cirru = -> cirru()
target.browserify = -> browserify()

target.compile = ->
  cirru()
  target.coffee yes
  browserify()

target.watch = ->
  station = mission.reload()

  mission.watch
    files: ['cirru/', 'coffee/']
    trigger: (filepath, extname) ->
      switch extname
        when '.cirru'
          cirru()
          station.reload project
        when '.coffee'
          filepath = path.relative 'coffee/', filepath
          mission.coffee
            file: filepath, from: 'coffee/', to: 'js/', extname: '.js'
            options:
              bare: yes
          browserify ->
            station.reload project

target.pre = ->
  target.compile()
  mission.bump
    file: 'package.json'
    options:
      at: 'prerelease'

target.sync = ->
  mission.rsync
    file: './'
    options:
      dest: 'tiye:~/repo/topics.tiye.me/'
      exclude: [
        'node_modules/'
        'bower_components/'
        'coffee'
        'README.md'
        'coffee'
        'js'
      ]