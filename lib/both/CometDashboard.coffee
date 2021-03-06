formatters = {
	del: (id) ->
		delHTML = formatters.link('#admin-delete-modal', formatters.icon('times'), 'hidden-xs btn btn-xs btn-danger btn-delete', 'data-toggle="modal" doc="' + id + '"')
		delHTML += formatters.link('#admin-delete-modal', formatters.icon('times'), 'visible-xs btn btn-sm btn-danger btn-delete', 'data-toggle="modal" doc="' + id + '"')
		delHTML

	edit: (id) ->
		collection = Session.get 'comet_collection'
		editHTML = formatters.link('/admin/' + collection + '/' + id + '/edit', formatters.icon('pencil'), 'hidden-xs btn btn-xs btn-primary')
		editHTML += formatters.link('/admin/' + collection + '/' + id + '/edit', formatters.icon('pencil'), 'visible-xs btn btn-sm btn-primary')
		editHTML

	formatDate: (date) ->
		if typeof CometConfig.dateStyle != 'undefined'
			dateStyle = CometConfig.dateStyle
		else
			dateStyle = 'MM/DD/YYYY'

		moment(date).format(dateStyle)

	formatDateFromNow: (date) ->
		if typeof CometConfig.dateStyle != 'undefined'
			dateStyle = CometConfig.dateStyle
		else
			dateStyle = 'MM/DD/YYYY'

		moment(date, dateStyle).fromNow()

	getAuxTitleWithLink: (id, viewType) ->
		if viewType == 'display'
			collection = Session.get 'comet_collection'
			auxList = CometConfig.collections[collection].auxCollections
			if auxList.length > 0
				if auxList.length == 1
					item = window[auxList[0]].find(id, {fields: {title: 1, _id: 1}}).fetch()
					linkUri = '/admin/' + auxList[0] + '/' + item[0]._id + '/edit'
					formatters.link(linkUri, item[0].title)
				else
					console.log 'multiple'

	getTitleWithLink: (id) ->
		collection = Session.get 'comet_collection'
		linkUri = '/admin/' + collection + '/' + id + '/edit'
		title = window[collection].find(id, {fields: {title:1}}).fetch()[0].title
		formatters.link(linkUri, title)

	getUserEmail: (user) ->
		if user && user.emails && user.emails[0] && user.emails[0].address
			email = user.emails[0].address
		else if user && user.services && user.services.facebook && user.services.facebook.email
			email = user.services.facebook.email
		else if user && user.services && user.services.google && user.services.google.email
			email = user.services.google.email

		email

	getUserProfileLink: (id, viewType) ->
		if viewType == 'display'
			user = Meteor.users.find(id).fetch()
			email = formatters.getUserEmail(user[0])
			formatters.link('/admin/Users/' + id + '/edit', email)

	icon: (iconClass, iconAlt) ->
		altText = ""
		if typeof iconAlt != 'undefined'
			altText = ' data-placement="right" data-toggle="tooltip" title="' + iconAlt + '"'

		'<i class="fa fa-' + iconClass + '"' + altText + '></i>';

	isAdmin: (id) ->
		if Roles.userIsInRole(id, ['superadmin', 'admin'])
			if Roles.userIsInRole(id, ['superadmin'])
				formatters.icon('space-shuttle', 'Super Admin')
			else
				formatters.icon('check', 'Admin')
		else
			formatters.icon('times')

	link: (href, content, classes='admin-link', extraLinkParams='') ->
		'<a href="' + href + '" class="' + classes + '" ' + extraLinkParams + '>' + content + '</a>'

	mailLink: (email) ->
		formatters.link('mailto:' + email[0].address, formatters.icon('envelope'), 'btn btn-default btn-xs')

	openInModal: (content, viewType) ->
		if viewType == 'display'
			randomId = new Mongo.ObjectID()
			html = formatters.link('#modal' + randomId, formatters.icon('eye'), 'hidden-xs btn btn-xs btn-default', 'data-toggle="modal" data-target="#modal' + randomId + '"')
			html += formatters.link('#modal' + randomId, formatters.icon('eye'), 'visible-xs btn btn-sm btn-default', 'data-toggle="modal" data-target="#modal' + randomId + '"')
			html += '<div class="modal fade in" id="modal' + randomId + '" tabindex="-1" role="dialog"><div class="modal-dialog"><div class="modal-content">'
			html += '<div class="modal-header"><h4 class="modal-title">' + Session.get "comet_collection" + '</h4></div>'
			html += '<div class="modal-body">' + content + '</div>'
			html += '<div class="modal-footer"><button type="button" class="btn btn-default" data-dismiss="modal">Close</button>'
			html += '</div></div>'
			html
}

CometDashboard =
	schemas: {}
	formatters: formatters
	coreColumns: {
		users:[
			{title: 'Admin', data: '_id', render: formatters.isAdmin, sortable: false, width: '5%', class: 'text-center'},
			{title: 'Email', data: '_id', render: formatters.getUserProfileLink},
			{title: 'Mail', data: 'emails', render: formatters.mailLink, sortable: false, width: '5%', class: 'text-center'},
			{title: 'Joined', data: 'createdAt', render: formatters.formatDate},
			{title: 'Edit', data: '_id', render: formatters.edit, sortable: false, width: '5%', class: 'text-center'},
			{title: 'Delete', data: 'id', render: formatters.del, sortable: false, width: '5%', class: 'text-center'}
		]
	}
	alertSuccess: (message)->
		Session.set 'cometSuccess', message
	alertFailure: (message)->
		Session.set 'cometError', message
	clearAlerts: ->
		Session.set 'cometSuccess', null
		Session.set 'cometError', null
		if typeof @.next == 'function'
			@next()
	checkAdmin: ->
		if not Roles.userIsInRole Meteor.userId(), ['superadmin', 'admin']
			if (typeof CometConfig?.nonAdminRedirectRoute == "string")
			  Router.go CometConfig.nonAdminRedirectRoute
		if typeof @.next == 'function'
			@next()
	cometRoutes: ['cometDashboard','cometDashboardUsersNew','cometDashboardUsersView','cometDashboardUsersEdit','cometDashboardView','cometDashboardNew','cometDashboardEdit','cometDashboardDetail', 'cometDashboardConfig']
	collectionLabel: (collection)->
		if collection == 'config'
			'Configure'
		else if collection == 'Users'
			'Users'
		else if collection? and typeof CometConfig.collections[collection].label == 'string'
			CometConfig.collections[collection].label
		else Session.get 'comet_collection'

CometDashboard.schemas.newUser = new SimpleSchema
	email:
		type: String
		label: "Email address"
	chooseOwnPassword:
		type: Boolean
		label: 'Let this user choose their own password with an email'
		defaultValue: true
	password:
		type: String
		label: 'Password'
		optional: true
	sendPassword:
		type: Boolean
		label: 'Send this user their password by email'
		optional: true

CometDashboard.schemas.sendResetPasswordEmail = new SimpleSchema
	_id:
		type: String

CometDashboard.schemas.changePassword = new SimpleSchema
	_id:
		type: String
	password:
		type: String
