# shell2web

### Example

 - Cached https://thawing-beyond-5538.herokuapp.com/

 - Live https://thawing-beyond-5538.herokuapp.com/live

### Notes

 - Whatever you want to run, name it `run`

 - The cached output page is at http://XXXXXXXX.herokuapp.com

 - Run the script live via http://XXXXXXXX.herokuapp.com/live (disable by LIVE=false)

### Local dev 

    foreman start

### Recommended web config & launch

    heroku create
    heroku config:set WEB_TIMEOUT=600
    heroku config:set WEB_CONCURRENCY=4
    git push heroku master


### Environment variable configuration options
    Variable                Default Value             Description
    -------------------------------------------------------------------------
    SHELL2WEB_CMD           ./run            what script to run
    SHELL2WEB_CONTENT_TYPE  text/plain       Content-Type
    SHELL2WEB_LIVE          true             allow /live ?
    SHELL2WEB_TIME          true             show start, end and elapsed time
    SHELL2WEB_DELAY         5 minutes        delay between background updates
    SHELL2WEB_AVG_RUN_TIME  4 minutes        estimated time a background update takes

**note: only supports 1 dyno**
