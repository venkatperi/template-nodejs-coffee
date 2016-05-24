path = require 'path'
src = [ 'lib/**/*.coffee', 'index.coffee' ]
dist = 'dist'
PROJECT_HOME = "#{process.env.HOME}/proj/repos"

config = ( grunt ) ->
  name = grunt.option 'name'
  grunt.fatal "Missing option: name" unless name?.length > 3
  version = grunt.option('version') or '0.1.0'
  description = grunt.option('description') or 'NEEDS DESCRIPTION'

  cwd = grunt.option('cwd') or process.cwd()
  target = path.join cwd, name
  if grunt.file.exists target
    grunt.fail.fatal "file or directory exists: #{target}. Won't clobber."
  console.log "name: #{name}", version, description

  data =
    name : name
    version : version
    description : description

  tasks :
    coffee :
      options : { sourceMap : false, bare : true, force : true }
      dist : { expand : true, src : src, dest : dist, ext : '.js' }

    clean : { dist : [ dist, '*.{js,map}', 'lib/**/*.{map,js}' ] }

    coffeelint : { app : src }

    watch : { coffee : { tasks : [ 'coffee' ], files : src } }

    copy :
      template :
        expand : true
        cwd : 'template/'
        src : '**'
        dest : "#{target}/"
        options :
          dot : true  # copy .dot files
          process : ( content, srcpath ) ->
            grunt.template.process content, data : data

    exec :
      gitInit :
        options : { cwd : target }
        cmd : 'git init'
      npmInstall :
        options : { cwd : target }
        cmd : 'npm install'
      mocha : { cmd : 'mocha --require ./coffee-coverage-loader.coffee' }
      istanbul : { cmd : 'istanbul report lcov' }
      open_coverage : { cmd : 'open ./coverage/lcov-report/index.html' }

  register :
    coverage : [ 'exec:istanbul', 'exec:open_coverage' ]
    test : [ 'exec:mocha', 'coverage' ]
    default : [ 'copy:template' ]

doConfig = ( cfg ) -> ( grunt ) ->
  opts = cfg grunt
  pkg = opts.tasks.pkg = grunt.file.readJSON "package.json"
  grunt.initConfig opts.tasks
  opts.load ?= []
  dev = Object.keys pkg.devDependencies
  deps = (f for f in dev when f.indexOf('grunt-') is 0)
  opts.load = opts.load.concat deps
  grunt.loadNpmTasks t for t in opts.load

  for own name, tasks of opts.register
    grunt.registerTask name, tasks

module.exports = doConfig config
