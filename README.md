# shell2web

Whatever you want to run, name it `run`

The cached page will show up at http://XXXXXXXX.herokuapp.com

The script can be forced to run by visiting http://XXXXXXXX.herokuapp.com/live (disable by LIVE=false)

### Local dev 

    foreman start

### Recommended web config & launch

    heroku create
    heroku config:set WEB_TIMEOUT=600
    heroku config:set WEB_CONCURRENCY=4
    git push heroku master



### Example

 - Cached https://thawing-beyond-5538.herokuapp.com/

 - Live https://thawing-beyond-5538.herokuapp.com/live

**note: only supports 1 dyno**
