require('dotenv').config()
const express = require('express')
const app = express()
const bodyParser = require('body-parser')
const Joi = require('joi-browser')
const path = require('path')
const request = require('request-promise')
const mailChimpBaseUrl = "https://us11.api.mailchimp.com/3.0"
const mailChimpListUrl = `/lists/${process.env.MAILCHIMP_LIST}/members/`
const mailChimpAuthorization = `apikey ${process.env.MAILCHIMP_API}`

const bodySchema = Joi.object({
  email: Joi.string().email().required(),
  fname: Joi.string().min(1).required(),
  lname: Joi.string().min(1).required()
})

app.use(bodyParser.json())
app.use(express.static(path.join(__dirname, 'dist')))

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

app.listen(process.env.BUILD_SERVER_PORT, () => console.log(`build server running on ${process.env.BUILD_SERVER_PORT}`))
