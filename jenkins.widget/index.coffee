# ------------------------------ CONFIG ------------------------------

user                = 'your username'       # your jenkins login username, change it if you have auth in jenkins
token               = 'your token'          # your jenkins access token, change it if you have auth in jenkins
serverUrlWithAuth 	= 'jenkins url'			# without http://
serverUrlNoAuth 	= 'jenkins url'			# with http://

# ------------------------------ END CONFIG --------------------------

# uncomment when server has authentication
command: "curl -sS #{user}:#{token}@#{serverUrlWithAuth}/api/json?depth=2&tree=jobs[displayName,lastBuild[builOn,duration,timestamp,result]]&exclude=hudson/job[lastBuild[result=%27SUCCESS%27]]"

# uncomment when server has no authentication
# command: "curl -sS @#{serverUrlNoAuth}/api/json?depth=2&tree=jobs[displayName,lastBuild[builOn,duration,timestamp,result]]&exclude=hudson/job[lastBuild[result=%27SUCCESS%27]]"



refreshFrequency: 60000 # ms

style: """
    bottom: 20px 
    left: 20px
    color: #fff
    font-family: Helvetica Neue

	@font-face
    	font-family Weather
    	src url(jenkins.widget/icons.svg) format('svg')
    p 
        font-size: 16px
	td
		font-size: 14px
		font-weight: 200
		padding-right: 18px
		height: 35px;
	th
		font-size: 14px
		font-weight: 200
		padding-right: 18px
		text-align: left
	
	#table
  		border-collapse:collapse 
  		
	#table thead th
		padding-bottom: 10px

	#table thead tr th
		border-bottom: 1px solid #fff
		padding-bottom: 10px


	.icon
    	display: inline-block
    	font-family: Weather
    	vertical-align: top
    	font-size: 15px
    	max-height: icon-size
    	vertical-align: middle
    	text-align: center
    	width: 20px
    	max-width: 20px
	
"""
    
render: (output) ->
	
	#change to your CI server name
	machine = 'Luke Skywalker'
	
	"""    
    <table id="table">
		<thead>
			<tr>
				<th>#{machine}</th>
				<th></th>
				<th>status</th>
				<th>result</th>
				<th>duration</th>
				<th>last success</th>
				<th>last failure</th>
			</tr> 
		</thead>
		<tbody class="separator" id="data">
		</tbody>
    </table>
	"""
	
	
renderInfo: (project, health, status, result, duration, lastSuccess, lastFailure) ->
	
	"""
    	<tr>
			<td>#{project}</td>
			<td><div class="icon">#{health}</div></td>
			<td>#{status}</td>
			<td>#{result}</td>
			<td>#{duration}</td>
			<td>#{lastSuccess}</td>
			<td>#{lastFailure}</td>
		</tr>
	"""     
	
update: (output, dom) ->
	
	#first we clean up the html
	$(dom).find('#data').html ''
	
	#we parse the json response
	data = JSON.parse(output)
	
	#and teh we append the new data
	for job in data.jobs then do =>
		$(dom).find('#data').append @renderInfo(job.displayName, 
												@getIcon(job.healthReport),
												job.lastBuild.building && 'running' || 'finished',
												if job.lastBuild.result == null 
												then 'n/a' 
												else  job.lastBuild.result.toLowerCase(),
												if job.lastBuild.result == null  
												then 'n/a'
												else @convertMilliseconds(job.lastBuild.duration), 
												@calculateDateDiffToNowUTC(job.lastSuccessfulBuild.timestamp), 
												@calculateDateDiffToNowUTC(job.lastUnsuccessfulBuild.timestamp))
		
		
#converts milliseconds to meaningful data
convertMilliseconds: (time) ->
	
	seconds = time / 1000
	minutes = parseInt(seconds/60, 10)
	seconds = parseInt(seconds % 60)
	hours = parseInt(minutes/60, 10)
	minutes = minutes % 60
	
	
	if hours >= 24
		days = parseInt(hours/24, 10)
		hours = hours % 24
	else
		days = 0
	
	if days > 0
		
		if hours == 0
			return days+'d '
		else
			return days+'d '+hours+'h '
		
	else if hours > 0
		return hours+'h '+minutes+'m '
	else
		return minutes+'m '+seconds+'s'
		
		
#calculates how long ago was dateUTC		
calculateDateDiffToNowUTC: (dateUTC) ->
	return @convertMilliseconds(new Date().getTime() - dateUTC)
	
	
#get's the weather icon	
getIcon: (healthReport) ->
	
	if healthReport.lenght == 0
		@iconMapping[11] 
		return
	
	healthStatus = healthReport[0].score
	if  healthReport.lenght > 1 && healthStatus > healthReport[1].score
		healthStatus = healthReport[1].score
	
	if healthStatus <= 20
		@iconMapping[11] 								#tornado	
	else if healthStatus > 20 && healthStatus <= 40
		@iconMapping[22] 								#showers	
	else if healthStatus > 40 && healthStatus <= 60
		@iconMapping[26] 								#cloudy	
	else if healthStatus > 60 && healthStatus <= 80
		@iconMapping[30] 								#partly cloudy	
	else if healthStatus > 80
		@iconMapping[32] 								#sunny	
	
	
	
#weather icon mapping	
iconMapping:
  0    : "&#xf021;" # tornado
  1    : "&#xf021;" # tropical storm
  2    : "&#xf021;" # hurricane
  3    : "&#xf019;" # severe thunderstorms
  4    : "&#xf019;" # thunderstorms
  5    : "&#xf019;" # mixed rain and snow
  6    : "&#xf019;" # mixed rain and sleet
  7    : "&#xf019;" # mixed snow and sleet
  8    : "&#xf019;" # freezing drizzle
  9    : "&#xf019;" # drizzle
  10   : "&#xf019;" # freezing rain
  11   : "&#xf019;" # showers
  12   : "&#xf019;" # showers
  13   : "&#xf01b;" # snow flurries
  14   : "&#xf01b;" # light snow showers
  15   : "&#xf01b;" # blowing snow
  16   : "&#xf01b;" # snow
  17   : "&#xf019;" # hail
  18   : "&#xf019;" # sleet
  19   : "&#xf002;" # dust
  20   : "&#xf014;" # foggy
  21   : "&#xf014;" # haze
  22   : "&#xf014;" # smoky
  23   : "&#xf021;" # blustery
  24   : "&#xf021;" # windy
  25   : "&#xf021;" # cold
  26   : "&#xf013;" # cloudy
  27   : "&#xf031;" # mostly cloudy (night)
  28   : "&#xf002;" # mostly cloudy (day)
  29   : "&#xf031;" # partly cloudy (night)
  30   : "&#xf002;" # partly cloudy (day)
  31   : "&#xf02e;" # clear (night)
  32   : "&#xf00d;" # sunny
  33   : "&#xf031;" # fair (night)
  34   : "&#xf00c;" # fair (day)
  35   : "&#xf019;" # mixed rain and hail
  36   : "&#xf00d;" # hot
  37   : "&#xf019;" # isolated thunderstorms
  38   : "&#xf019;" # scattered thunderstorms
  39   : "&#xf019;" # scattered thunderstorms
  40   : "&#xf019;" # scattered showers
  41   : "&#xf01b;" # heavy snow
  42   : "&#xf01b;" # scattered snow showers
  43   : "&#xf01b;" # heavy snow
  44   : "&#xf00c;" # partly cloudy
  45   : "&#xf019;" # thundershowers
  46   : "&#xf00c;" # snow showers
  47   : "&#xf019;" # isolated thundershowers
  3200 : "&#xf00c;" # not available
	
	
	
	
	
	
	
	
	
	
	
 