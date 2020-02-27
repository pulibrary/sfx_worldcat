# SFX_Worldcat

Retrieve records from Worldcat based on identifiers found in the SFX KB.

## To run the script on the server:
`ssh deploy@lib-jobs-staging1`
`cd /opt/sfx_worldcat/current/`
`bundle exec rake run_incremental &`

The process will create 4 putput files in /opt/sfx_worldcat/current/output which will need to be copied to Voyager for processing.  In the future these may be automatically copied to a shared drive with voyager.

## To reset kill the process
`ps -ef |grep ruby `
`kill -9 <proc number>`

## To reset to run again
`cd /opt/sfx_worldcat/current/output/incremental`
`rm *{current_date}*`

## To Deploy to the server
`cap staging deploy`
`cap production deploy`
