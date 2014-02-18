Bejoo.sapiURL = window.Bejoo.sapiurl + "organisation/"

Handlebars.registerHelper 'printDate', (date) ->
	moment(date).format 'DD.MM.YYYY'

Backbone.Marionette.TemplateCache::compileTemplate = (rawTemplate) ->
	Handlebars.compile rawTemplate

getAuthKey = ->
	if sessionStorage.authKey
		deferred = new $.Deferred

		deferred.resolve
			key: sessionStorage.authKey

		deferred
	else
		request = $.ajax
			url: "#{Bejoo.baseUrl}common/auth/key"
			dataType: 'json'

		request.done (data) ->
			sessionStorage.authKey = data.key

		request


setAuthKey = (key) ->
	originalSync = Backbone.sync

	Backbone.sync = (method, model, options) ->
		options.headers = options.headers || {};
		_.extend options.headers, {'Authorization': "Token #{key}"}
		originalSync.call(model, method, model, options);

positionsApp = new Backbone.Marionette.Application

positionsApp.addRegions
	compoundView: '#compound-view'

positionsApp.module 'Helpers', (Helpers, App, Backbone, Marionette, $, _) ->


positionsApp.module 'Models', (Models, App, Backbone, Marionette, $, _) ->

	class Models.Position extends Backbone.Model

	class Models.Positions extends Backbone.Collection
		model: Models.Position
		url: "#{Bejoo.sapiURL}position"

	class Models.Round extends Backbone.Model

		close: ->
			Bejoo.requestHelper "#{Bejoo.sapiURL}round/#{@get('id')}/close"

	class Models.Rounds extends Backbone.Collection
		model: Models.Round

		initialize: ->
			@listenTo @, 'add', (round, rounds) =>
				name = round.get 'name'
				processedName = if name is '' then "Runde #{@rounds.length - rounds.indexOf(round)}" else name
				round.set 'name', processedName

		comparator: (a, b) ->
			if a.get('created_at') < b.get('created_at') then 1 else -1

	class Models.Application extends Backbone.Model
		promote: ->
			Bejoo.requestHelper "#{Bejoo.sapiURL}application/#{@get('id')}/promote"

		close: ->
			Bejoo.requestHelper "#{Bejoo.sapiURL}application/#{@get('id')}/close"

	class Models.Applications extends Backbone.Collection
		model: Models.Application



positionsApp.module 'Views', (Views, App, Backbone) ->

	class Views.CreatePosition extends Marionette.View
		template: Handlebars.compile $('#create-view-template').html()
		el: 'article#content'
		events:
			'click .submit-position': 'submitPosition'
			'click .x': 'hide'
			'change #workload-position': 'workloadChanged'

		ui:
			title: '.title-position'
			description: '.description-position'
			workload: '#workload-position'
			from: '.from-position'
			to: '.to-position'
			pensum: '.pensum-number'

		initialize: ->

		show: ->
			if not $('article#content #create-panel').length
				$('article#content').prepend @render()
				@bindUIElements()
			else
				$('#create-panel').show()

		hide: ->
			$('#create-panel').hide()

		render: ->
			@template { }

		onDomRefresh: ->
			@workloadChanged()


		submitPosition: (e) ->
			e.preventDefault()
			console.log 'submit'
			formData = @formData()
			formData.created_at = new Date
			formData.closed_at = new Date
			formData.user_id = 83
			console.log formData

			position = new positionsApp.Models.Position formData

			positionsApp.vent.trigger 'position:add', position

			position.save()

		formData: ->
			title: @ui.title.val()
			description: @ui.description.val()
			workload: parseFloat @ui.workload.val(), 10
			from: new Date @ui.from.val()
			to: new Date @ui.to.val()

		calculatePensum: (weekMax, workload) ->
			Math.round(workload / weekMax * 1000) / 10

		workloadChanged: ->
			workload = parseFloat @ui.workload.val(), 10
			@ui.pensum.html @calculatePensum 40, workload


	class Views.PositionListView extends Backbone.Marionette.ItemView
		template: '#position-list-item-template'
		tagName: 'li'
		className: 'list-group-item position-list-element'
		events:
			'click': 'selectPosition'

		selectPosition: ->
			App.vent.trigger 'positionsList:selected', @model.get 'id'

	class Views.PositionsListView extends Backbone.Marionette.CompositeView
		tagName: 'ul'
		className: 'list-group'
		itemView: Views.PositionListView
		template: '#position-list-view-template'
		itemViewContainer: '.position-list-view-container'

		events:
			'click #create-position': 'createPosition'

		createPosition: ->
			if not @createView
				@createView = new Views.CreatePosition
			@createView.show()


	class Views.RoundView extends Backbone.Marionette.ItemView
		template: '#positions-round-template'
		className: 'position-round-element'
		events:
			'click .close-round': 'closeRound'

		onRender: ->
			applicationsCollection = new App.Models.Applications @model.get 'applications'

			applicationsView = new App.Views.ApplicationsView
				collection: applicationsCollection

			@$el.append applicationsView.el
			applicationsView.render()

		closeRound: ->
			@model.close()

	class Views.RoundsView extends Backbone.Marionette.CollectionView
		itemView: Views.RoundView

	class Views.ApplicationView extends Backbone.Marionette.ItemView
		template: '#positions-appliation-template'
		className: 'position-application-element col-md-2'
		events:
			'click .application-accept': 'acceptApplication'
			'click .application-decline': 'closeApplication'

		acceptApplication: ->
			@model.collection.trigger 'application:accepted'
			@model.promote()

		closeApplication: ->
			@model.collection.trigger 'application:closed'
			@model.close()

		onRender: ->
			console.log @model

	class Views.ApplicationsView extends Backbone.Marionette.CollectionView
		itemView: Views.ApplicationView
		className: 'row'

	class Views.PositionView extends Backbone.Marionette.CompositeView
		template: '#position-item-template'
		className: 'panel panel-default'
		itemView: Views.RoundView
		itemViewContainer: '.rounds'

		onRender: ->
			roundCollection = @model.get 'rounds'

			roundsView = new App.Views.RoundsView
				collection: roundCollection

			@$el.append roundsView.el
			roundsView.render()

			# @$el.affix
			# 	offset:
			# 		top: 80

positionsApp.module 'Controller', (PositionsController, App, Backbone, Marionette, $, _) ->

	class PositionsController.Controller extends Marionette.Controller
		constructor: ->
			@positions = new App.Models.Positions

		start: ->
			that = @
			authKeyRequest = getAuthKey()
			authKeyRequest.done (keyData) =>
				Bejoo.requestHelper = (url, data) ->
					$.ajax
						dataType: 'json'
						url: url
						data: data
						type: 'POST'
						headers: {'Authorization': "Token #{keyData.key}"}

				setAuthKey keyData.key

				@init()

			App.vent.on 'position:add', (position) ->
				that.positions.add position

		init: ->
			compoundView = new Marionette.CompoundView
				listView: App.Views.PositionsListView,
				itemView: App.Views.PositionView,
				collection: @positions,
				template: '#compound-view-template',
				breakWidth: 750

			request = @prepareData()
			request.then ->
				App.compoundView.show compoundView

		prepareData: ->
			request = @positions.fetch()

			request.then =>
				@positions.forEach (position) ->
					rounds = new App.Models.Rounds position.get('rounds')

					counter = rounds.length

					rounds.forEach (round) ->
						counter = counter - 1
						name = round.get 'name'
						round.set 'name', if name is '' then "Runde #{counter}" else name

					position.set 'rounds', rounds
					#console.log position


	PositionsController.addInitializer ->
		controller = new PositionsController.Controller

		controller.start()


positionsApp.start()

