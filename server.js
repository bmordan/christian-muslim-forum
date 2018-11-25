const express = require('express')
const app = express()
const async = require('async')
const bodyParser = require('body-parser')
const path = require('path')
const graphql = require('graphql-request').request
const build = require('./bin/main')

const queue = async.queue((task, complete) => task(complete), 1)
queue.drain(() => console.log(new Date(), ' queue.drained'))


app.use(bodyParser.json())
app.use(express.static(path.join(__dirname, 'dist')))

app.post('/graphql', (req, res) => {
  graphql('http://46.101.6.182/graphql', req.body.query)
  .then(data => {
    return res.json(data)
  })
  .catch(err => res.send(err));
})

app.get('/api/build', (req, res) => {
  console.log('\nfrom', req.referrer)
  console.log('\nadding to queue of ', queue.length())
  queue.push(build)
  return res.send({queue: queue.length()})
})

app.get('/api/empty-queue', (req, res) => {
  queue.pause()
  queue.remove(() => true)
  queue.resume()
  return res.send({queue: queue.length()})
})

app.listen(3030, () => console.log(`build server running on 3030`))
