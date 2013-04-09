delay = (ms, func) -> setTimeout func, ms

angular.module("data", ["ngResource"]).factory "Event", ($resource) ->
  Event = $resource("/data/events/:id", {}
  ,
    update:
      method: "PUT"
  )
  Event::update = (cb) ->
    Event.update
      id: @_id #@_id.$oid
    , angular.extend({}, this,
      _id: `undefined`
    ), cb

  Event::destroy = (cb) ->
    Event.remove
      id: @_id
    , cb

  Event

window.MainCntl = ($scope, $route, $routeParams, $location, $http) ->
  $scope.$route = $route
  $scope.$location = $location
  $scope.$routeParams = $routeParams
  $scope.crumbs = [ '/opp/addtitle=Add Title', '/opp/dash=Dashboard',
                    '/opp/settings=Settings','/opp/Settings=Settings',
                    '/opp=Opportunities', '/=OARS' ]
  $scope.breadcrumb = ->
    path = $scope.$location.path()
    parts = []
    for str, i in $scope.crumbs
      if str? and str?.length > 0
        [ pathpart, name ] = str.split '='
      if path.indexOf(pathpart) >= 0
        parts.unshift { path: pathpart, name: name }
    parts

SelectCntl = ($scope, $routeParams, $resource) ->
  $scope.$resource = $resource
  $scope.name = "SelectCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()

DashCntl = ($scope, $routeParams, $resource) ->
  $scope.$resource = $resource
  $scope.name = "DashCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()

AddTitleCntl = ($scope, $routeParams) ->
  $scope.name = "AddTitleCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()

SettingsCntl = ($scope, $routeParams) ->
  $scope.name = "SettingsCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()

ListCntl = ($scope, Event) ->
  $scope.events = Event.query()

NewEventCntl = ($scope, $location, Event) ->
  $scope.save = ->
    Event.save $scope.event, (event) ->
      $location.path "/opp/settings"

EditEventCntl = ($scope, $location, $routeParams, Event) ->
  self = this
  Event.get
    id: $routeParams.eventId
  , (event) ->
    event.date = new Date(event.date)
    self.original = event
    $scope.event = new Event(self.original)

  $scope.isClean = ->
    angular.equals self.original, $scope.event

  $scope.destroy = ->
    self.original.destroy ->
      $location.path "/opp/settings"

  $scope.save = ->
    $scope.event.update ->
      $location.path "/opp/settings"

mod = ($routeProvider, $locationProvider) ->
  $routeProvider.when "/",
    templateUrl: "/select.html"
    controller: SelectCntl

  $routeProvider.when "/opp/dash",
    templateUrl: "/dash.html"
    controller: DashCntl

  $routeProvider.when "/opp/addtitle",
    templateUrl: "/addtitle.html"
    controller: AddTitleCntl

  $routeProvider.when "/opp/settings",
    templateUrl: "/settings.html"
    controller: SettingsCntl

  $routeProvider.when "/opp/event/new",
    templateUrl: "/eventdetail.html"
    controller: NewEventCntl

  $routeProvider.when "/opp/event/edit/:eventId",
    templateUrl: "/eventdetail.html"
    controller: EditEventCntl

  $locationProvider.html5Mode true

viewMod = angular.module "ngView", [ "ngResource", "data", "ui" ], mod


viewMod.directive "feed", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  template: "<div><li ng-class=\"{doneloading: (articles.length>0)}\">Loading...</li><li ng-repeat=\"article in articles\"><a href=\"{{article.link}}\" target=\"_blank\" >{{article.title}}</a></li></div>"
  link: (scope, element, attrs) ->
    Feed = $resource "/feed/" + encodeURIComponent(attrs.url)
    scope.$on 'selpane', (ev) ->
      scope.articles = Feed.query( {  }, ->  )

viewMod.directive "upcoming", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  template: "<li ng-repeat=\"ev in evts\"><a href=\"/opp/event/edit/{{ev._id}}\">{{ev.date}} {{ev.description}}</a></li>"
  link: (scope, element, attrs) ->
    Upcoming = $resource "/upcoming"
    scope.evts = Upcoming.query( { blah: 'hello' }, ->  )
    scope.$on

viewMod.directive 'tabs', ->
  restrict: 'E'
  transclude: true
  controller: ($scope, $element) ->
    panes = $scope.panes = []

    $scope.select = (pane) ->
      for p in panes
        p.selected = false
      pane.selected = true
      $scope.$broadcast 'selpane', {test:1}

    @addPane = (pane) ->
      if panes.length is 0 then $scope.select pane
      panes.push pane
  template:
    """
    <div class="tabbable">
      <ul class="nav nav-tabs">
        <li ng-repeat="pane in panes" ng-class="{active:pane.selected}">
          <a href="" ng-click="select(pane)">{{pane.title}}</a>
        </li>
      </ul>
      <div class="tab-content" ng-transclude></div>
    </div>
    """
  replace: true

viewMod.directive 'pane', ->
  require: '^tabs'
  restrict: 'E'
  transclude: true
  scope: { title: '@' }
  controller: ($scope, $element) ->
    $scope.$on 'selpane', (ev, opts) ->
      console.log 'pane selpane event'
      return
      #console.log ev
  link: (scope, element, attrs, tabsCtrl) ->
    tabsCtrl.addPane scope
  template:
    '<div class="tab-pane" ng-class="{active: selected}" ng-show="selected" ng-transclude>' +
    '</div>'
  replace: true
