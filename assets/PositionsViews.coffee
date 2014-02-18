positionsApp.module 'Views', (Views, App, Backbone) ->
	Helpers =
		calculatePensum: ((weeklyHours) ->
				(workload) ->
					Math.round(workload / weeklyHours * 1000) / 10
			)(Bejoo.organisation.weeklyHours)


	class Views.CreatePosition extends Marionette.View
		template: Handlebars.compile $('#create-view-template').html()
		el: 'article#content'
		events:
			'click .submit-position': 'submitPosition'
			'click .x': 'hide'
			'change #workload-position': 'workloadChanged'

		ui:
			title: '.title-position'
			indefinite: '#indefinite'
			description: '.description-position'
			workload: '#workload-position'
			from: '.from-position'
			to: '.to-position'
			pensum: '.pensum-number'
			duration: '#duration'
			mon: '#mon'
			tue: '#tue'
			wed: '#wed'
			thu: '#thu'
			fri: '#fri'
			sat: '#sat'
			sun: '#sun'

		show: ->
			if not $('article#content #create-panel').length
				$('article#content').prepend @render()
				@bindUIElements()
				@workloadChanged()
			else
				$('#create-panel').show()

		hide: ->
			$('#create-panel').hide()

		render: ->
			@template { }

		submitPosition: (e) ->
			e.preventDefault()
			formData = @formData()
			formData.created_at = new Date
			formData.closed_at = new Date
			formData.user_id = 83

			position = new positionsApp.Models.Position formData

			positionsApp.vent.trigger 'position:add', position

			position.save()

		checkboxToValue: (box) ->
			if box.is ':checked' then 1 else 0

		formData: ->
			title: @ui.title.val()
			description: @ui.description.val()
			workload: parseFloat @ui.workload.val(), 10
			from: new Date @ui.from.val()
			to: new Date @ui.to.val()
			duration: @ui.duration.val()
			indefinite: @ui.indefinite.val()
			weekdays:
				Mon: @checkboxToValue @ui.mon
				Tue: @checkboxToValue @ui.tue
				Wed: @checkboxToValue @ui.wed
				Thu: @checkboxToValue @ui.thu
				Fri: @checkboxToValue @ui.fri
				Sat: @checkboxToValue @ui.sat
				Sun: @checkboxToValue @ui.sun

		workloadChanged: ->
			workload = parseFloat @ui.workload.val(), 10
			@ui.pensum.html Helpers.calculatePensum workload

