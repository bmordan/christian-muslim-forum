const build = require('./build')
const tasks = require('./tasks')
const { map } = require('ramda')

// map(build, tasks)
build(tasks[5])
