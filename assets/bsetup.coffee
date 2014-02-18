Bejoo.sapiURL = window.Bejoo.sapiurl + "organisation/"

Handlebars.registerHelper 'printDate', (date) ->
	moment(date).format 'DD.MM.YYYY'

Backbone.Marionette.TemplateCache::compileTemplate = (rawTemplate) ->
	Handlebars.compile rawTemplate

