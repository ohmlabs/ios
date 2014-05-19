module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    concat:
      options:
        separator: ";"

      dist:
        src: ["javascripts/**/*.js"]
        dest: "js/<%= pkg.name %>.js"

    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= grunt.template.today(\"dd-mm-yyyy\") %> */\n"

      dist:
        files:
          "js/<%= pkg.name %>.min.js": ["<%= concat.dist.dest %>"]

    # browser sync works with the watch task to inject css when updated
    browser_sync:
      dev:
        bsFiles:
          src : 'static/css/style.css'
        options:
          watchTask: true

    compass:
      dev:
        options:
          config: "config/config.rb"
      prod:
        options:
          config: "config/prod_config.rb"

    # this watch task does a lot:
    #     1.) compile sass
    #     2.) concat and minify js
    #     3.) reload the page if js or dom changed
    #     4.) restart the server if necessary
    watch:
      sass:
        files: "client/**/*.sass"
        tasks: "compass:dev"
      scripts:
        files: '<%= concat.dist.src %>'
        tasks: ['concat', 'coffee', 'copy']
      livereload:
        options:
          livereload: true
        files: ["static/js/*.js", "static/css/*.css", "server/views/**/*"]
      server:
        files: ["gruntfile.coffee", "ohm.coffee", "server/**/*.js"]
        tasks: ["coffee", "forever:restart"]
                          
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-compass"
  grunt.loadNpmTasks "grunt-browser-sync"
  # the bare grunt command only compiles
  grunt.registerTask "default", ["compass:dev"]
  # in production, concat and minify
  grunt.registerTask "prod", ["concat", "uglify", "compass:prod"]
