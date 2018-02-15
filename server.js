require('dotenv').config()
const express = require('express')
const app = express()
const bodyParser = require('body-parser')
const Joi = require('joi-browser')
const path = require('path')
const request = require('request-promise')
const mailChimpBaseUrl = "https://us11.api.mailchimp.com/3.0"
const mailChimpListUrl = `/lists/${process.env.MAILCHIMP_LIST}/members/`
const mailChimpCredientials = new Buffer(`user:${process.env.MAILCHIMP_API}`, 'binary').toString('base64')
const {
  pick,
  pipe,
  pipeP,
  prop,
  assoc,
  assocPath,
  converge,
  pluck,
  tap,
  lensProp
} = require('ramda')


const bodySchema = Joi.object({
  email: Joi.string().email().required(),
  fname: Joi.string().min(1).required(),
  lname: Joi.string().min(1).required()
})

app.use(bodyParser.json())
app.use(express.static('public'))

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'))
})

app.post('/subscribe', (req, res) => {
  Joi.validate(req.body, bodySchema, (err, value) => {
    if (err) return res.send(err)

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
        Authorization: `apikey ${process.env.MAILCHIMP_API}`
      },
      body: payload,
      json: true
    }).then((res) => {
      res.send('success added to mailchimp')
    }).catch((err) => {
      res.send(err)
    })
  })
})

app.listen(3030, () => console.log('api server running on 3030'))
