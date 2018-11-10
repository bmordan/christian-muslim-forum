// require('dotenv').config()
const express = require('express')
const app = express()
const async = require('async')
const bodyParser = require('body-parser')
const path = require('path')
const request = require('request-promise')
const build = require('./bin/main')
const mailChimpBaseUrl = "https://us11.api.mailchimp.com/3.0"
const mailChimpListUrl = `/lists/${process.env.MAILCHIMP_LIST}/members/`
const mailChimpAuthorization = `apikey ${process.env.MAILCHIMP_API}`

const queue = async.queue((task, complete) => task(complete), 1)
queue.drain(() => console.log(new Date(), ' queue.drained'))

const validate = (body, cb) => {
  const props = ['email', 'fname', 'lname']
  const validProps = Object.keys(body).every(key => props.indexOf(key) > -1)
  const validValues = props.every(prop => typeof body[prop] === 'string')
  const valid = [validProps, validValues].every(item => !!item)
  
  cb(valid)
}

app.use(bodyParser.json())
app.use(express.static(path.join(__dirname, 'dist')))

app.post('/subscribe', (req, res) => {
  validate(req.body, (valid) => {
    if (!valid) return res.send(err)

    const { email, fname, lname } = req.body

    const payload = {
      email_address: email,
      status: 'subscribed',
      merge_fields: {
        FNAME: fname,
        LNAME: lname
      },
      update_existing: true
    }

    request({
      method: 'POST',
      uri: mailChimpBaseUrl + mailChimpListUrl,
      headers: {
        'Content-Type': 'application/json',
        Authorization: mailChimpAuthorization
      },
      body: payload,
      json: true
    }).then(mailchimp_res => {
      const {
        status,
        email_address: email,
        merge_fields: {FNAME: fname}
      } = mailchimp_res
      return res.json({status, email, fname})
    }).catch(mailchimp_err => {
      return res.send(mailchimp_err)
    })
  })
})

app.get('/api/build', (req, res) => {
  console.log('\nfrom', req.referrer)
  console.log('\nadding to queue of ', queue.length())
  queue.push(build)
  return res.send({queue: queue.length()})
})

app.get('/api/empty-queue', (req, res) => {
  queue.pause()
  queue.remove(({data, priority}) => true)
  queue.resume()
  return res.send({queue: queue.length()})
})

app.listen(3030, () => console.log(`build server running on 3030`))
