module.exports = function addGoogleAnalytics (html) {
  return html.replace('<script id="gtag">', `<script id="gtag">window.dataLayer = window.dataLayer || [];function gtag(){dataLayer.push(arguments)};gtag('js',new Date());;gtag('config','UA-101196212-1');`)
}