delay = (ms, func) -> setTimeout func, ms

statuses = ['In Development', 'Pre-Production','Filming',
            'Post-Production', 'Completed']

opptypes = ['Agent/Manager', 'Distributor', 'Film Commission',
            'Film Festival', 'Film Market', 
            'Filmmaker/Screenwriter (Solicited Submission)',
            'Filmmaker/Screenwriter (Unsolicited Submission)',
            'Producer/Production Company',
            'Sales Agent, Domestic',
            'Sales Agent, International', 'Other']

genres = ['Action','Adventure','Animation','Biography/Biopic',
          'Comedy','Crime','Documentary','Drama','Experimental',
          'Family','Fantasy','Film Noir','History','Horror',
          'Martial Arts','Musical','Mystery','Romance',
          'Science Fiction','Sports','Thriller','War']

angular.module("dataevent", ["ngResource"]).factory "Event", ($resource) ->
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

angular.module("datauser", ["ngResource"]).factory "User", ($resource) ->
  User = $resource("/data/users/:id", {}
  ,
    update:
      method: "PUT"
  )
  User::update = (cb) ->
    User.update
      id: @name #@_id.$oid
    , angular.extend({}, this,
      _id: `undefined`
    ), cb

  User::destroy = (cb) ->
    User.remove
      id: @name
    , cb

  User


angular.module("dataopp", ["ngResource"]).factory "Opportunity", ($resource) ->
  Opportunity = $resource("/data/opportunity/:id", {}
  ,
    update:
      method: "PUT"
  )
  Opportunity::update = (cb) ->
    Opportunity.update
      id: @_id #@_id.$oid
    , angular.extend({}, this,
      _id: `undefined`
    ), cb

  Opportunity::destroy = (cb) ->
    Opportunity.remove
      id: @_id
    , cb

  Opportunity


angular.module("dataproject", ["ngResource"]).factory "Project", ($resource) ->
  Project = $resource("/data/projects/:id", {}
  ,
    update:
      method: "PUT"
  )
  Project::update = (cb) ->
    Project.update
      id: @_id #@_id.$oid
    , angular.extend({}, this,
      _id: `undefined`
    ), cb

  Project::destroy = (cb) ->
    Project.remove
      id: @_id
    , cb

  Project

window.MainCntl = ($scope, $route, $routeParams, $location, $resource, $http) ->
  $scope.$route = $route
  $scope.$location = $location
  $scope.$routeParams = $routeParams
  $scope.crumbs = [ '/opp/addtitle=Add Title', '/opp/dash=Dashboard',
                    '/opp/settings=Settings', '/opp/settings/adduser=Add User', 
                    '/opp/browse=Browse Titles','/opp=Opportunities', '/=OARS' ]

  UserData = $resource "/sessiondata"
  $scope.sessionInfo = UserData.get {}, (data) ->
    console.log 'sessionInfo is'
    console.log $scope.sessionInfo
    console.log 'data is '    
    console.log JSON.stringify(data)
    $scope.showaddtitle = $scope.sessionInfo.permissions.opportunities is 'readwrite'

  $scope.showView = true
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
  console.log $scope.$parent.sessionInfo
  $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities isnt 'none'

AddOpportunityCntl = ($scope, $location, $routeParams, Opportunity) ->
  $scope.name = "AddOpportunityCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()
  $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities is 'readwrite'
  $scope.opptypes = opptypes
  $scope.save = ->
    Opportunity.save $scope.opp, (project) ->
      $location.path "/opp/browse"

AddTitleCntl = ($scope, $location, $routeParams, $resource, Project) ->
  $scope.name = "AddTitleCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()
  $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities is 'readwrite'
  $scope.statuses = statuses
  $scope.genres = genres
  Opps = $resource "/data/opportunity"
  $scope.oppsources = Opps.query {}, ->

  $scope.addWriter = ->
    if $scope.project.writers?
      $scope.project.writers.push $scope.project.writeradd
    else
      $scope.project.writers = [ $scope.project.writeradd ]
    $scope.project.writeradd = ''
  $scope.delete = (idx) ->
    removeWriter $scope, idx
  $scope.addCast = ->
    if $scope.project.cast?
      $scope.project.cast.push $scope.project.castadd
    else
      $scope.project.cast = [ $scope.project.castadd ]
    $scope.project.castadd = ''
  $scope.deleteCast = (idx) ->
    $scope.project.cast.splice idx, 1
  $scope.delete = (idx) ->
    removeWriter $scope, idx
  $scope.save = ->
    if not $scope.project.reviews?
      $scope.project.reviews = []
    $scope.project.files = []
    $scope.project.projections = []
    Project.save $scope.project, (project) ->
      $location.path "/opp/browse"

ReviewsCtrl = ($scope) ->

  $scope.open = ->
    $scope.shouldBeOpen = true

  $scope.saveReview = ->
    $scope.closeMsg = 'I was closed at: ' + new Date()
    $scope.shouldBeOpen = false;
    alert 'savereview'

  $scope.items = ['item1', 'item2']

  $scope.opts =
    backdropFade: true
    dialogFade:true

SettingsCntl = ($scope, $routeParams, $resource) ->
  $scope.name = "SettingsCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()
  $scope.showadduser = $scope.$parent.sessionInfo.name is 'admin'
  $scope.showlistusers = $scope.$parent.sessionInfo.name is 'admin'
  $scope.showaddevent = $scope.$parent.sessionInfo.permissions.opportunities is 'readwrite'
  $scope.showaddopp = $scope.$parent.sessionInfo.permissions.opportunities is 'readwrite'  
  $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities isnt 'none'

ListUsersCntl = ($scope, $routeParams, $resource) ->
  $scope.name = "UserListCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()
  UserList = $resource "/data/users"
  $scope.users = UserList.query {}, ->

BrowseCntl = ($scope, $routeParams, $resource, Project, $location) ->
  $scope.name = "BrowseCntl"
  $scope.params = $routeParams
  $scope.$parent.crumblinks = $scope.$parent.breadcrumb()
  $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities isnt 'none'
  ProjectX = $resource "/data/projects"
  $scope.projects = ProjectX.query {}, ->
  $scope.statusesx = statuses
  Source = $resource "/data/sources"
  $scope.sources = Source.query {}, ->
  $scope.genres = genres

  $scope.closeViewOrAddReview = ->
    $scope.viewOrAdd = false

  $scope.readReviews = ->
    $scope.reviewNum = 0
    $scope.viewOrAdd = false
    $scope.viewMode = true
    $scope.review = $scope.project.reviews[0]
    $scope.editableReview = true
    $scope.shouldBeOpen = true    

  $scope.addReview = (project) ->
    $scope.reviewCount = $scope.project.reviews.length
    $scope.addingReview = true
    $scope.editableReview = false
    $scope.project = project
    $scope.viewOrAdd = false
    $scope.review =
      title: project.title
      writers: project.writers
      directors: project.directors
      status: project.status
      timestamp: new Date()
      rating: 0
    project.reviews.push $scope.review
    $scope.shouldBeOpen = true

  $scope.editReview = ->
    $scope.viewMode = false
    $scope.addingReview = false
    $scope.editableReview = false

  $scope.addViewReviews = (project) ->
    $scope.project = project
    $scope.viewOrAdd = false
    $('.modal-backdrop').show()
    if not project.reviews? or project.reviews?.length is 0
      project.reviews = []
      $scope.addReview project
    else
      $scope.shouldBeOpen = false
      $scope.viewOrAdd = true

  $scope.saveReview = ->
    console.log JSON.stringify($scope.project)
    ReviewAdder = $resource "/data/reviews/add/#{$scope.project._id}"
    ReviewAdder.save $scope.review, ->
      $scope.shouldBeOpen = false
      $location.path "/opp/browse"

  $scope.sendReview = ->
    email = prompt "Email address to send review to:"
    ReviewSender = $resource "/sendreview/#{email}"
    ReviewSender.save $scope.review, ->
      alert 'Review sent'      

  $scope.nextReview = ->
    if $scope.reviewNum < $scope.project.reviews.length-1
      $scope.reviewNum += 1
      $scope.review = $scope.project.reviews[$scope.reviewNum]

  $scope.previousReview = ->
    if $scope.reviewNum > 0
      $scope.reviewNum -= 1
      $scope.review = $scope.project.reviews[$scope.reviewNum]

  $scope.save = ->
    if not $scope.project.reviews?
      $scope.project.reviews = []
    $scope.project.files = []
    $scope.project.projections = []
    project.reviews.push $scope.review
    $scope.viewMode = false
    Project.save $scope.project, (project) ->
      $location.path "/opp/browse"

  $scope.close = (cancelled) ->
    if cancelled and $scope.addingReview
      if $scope.project.reviews.length > $scope.reviewCount
        $scope.project.reviews.pop()
    $scope.shouldBeOpen = false
    $scope.viewOrAdd = false
    $scope.viewMode = false
    $('.modal-backdrop').hide()

  $scope.opts =
    backdropFade: true
    dialogFade:true

  $scope.filter = () ->
    data = {}
    if $scope.filterStatus?
      data.status = $scope.filterStatus
    if $scope.filterSource?
      data.source = $scope.filterSource.name
    if $scope.filterGenre?
      data.genre = $scope.filterGenre
    str = JSON.stringify data
    $scope.projects = Project.query( { filter: str }, ->  )

ListCntl = ($scope, Event) ->
  $scope.events = Event.query()

NewEventCntl = ($scope, $location, Event) ->
  $scope.save = ->
    Event.save $scope.event, (event) ->
      $location.path "/opp/settings"

NewUserCntl = ($scope, $location, User) ->
  $scope.save = ->
    User.save $scope.user, (user) ->
      $location.path "/opp/settings"      

removeWriter = (scope, idx) ->
  scope.project.writers.splice idx, 1

EditProjectCntl = ($scope, $location, $routeParams, Project) ->
  self = this
  Project.get
    id: $routeParams.projectId
  , (project) ->
    self.original = project
    $scope.project = new Project(self.original)

  $scope.isClean = ->
    angular.equals self.original, $scope.project

  $scope.destroy = ->
    self.original.destroy ->
      $location.path "/opp/settings"

  $scope.save = ->
    $scope.project.update ->
      $location.path "/opp/settings"

EditUserCntl = ($scope, $location, $routeParams, $resource, User) ->
  self = this
  User.get
    id: $routeParams.userId
  , (user) ->    
    self.original = user   
    $scope.showpermissions = $scope.$parent.sessionInfo.name is 'admin'
    $scope.user = new User(self.original)

  $scope.isClean = ->
    angular.equals self.original, $scope.event

  $scope.destroy = ->
    self.original.destroy ->
      $location.path "/settings/listusers"

  $scope.save = ->
    $scope.user.update ->
      $location.path "/settings/listusers"

EditEventCntl = ($scope, $location, $routeParams, Event) ->
  self = this
  Event.get
    id: $routeParams.eventId
  , (event) ->
    event.date = new Date(event.date)
    self.original = event
    $scope.$parent.showView = $scope.$parent.sessionInfo.permissions.opportunities is 'readwrite'
    console.log 'inside editeventcntl sessioninfo is'
    console.log $scope.$parent.sessionInfo    
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

  $routeProvider.when "/opp/browse",
    templateUrl: "/browse.html"
    controller: BrowseCntl

  $routeProvider.when "/opp/event/new",
    templateUrl: "/eventdetail.html"
    controller: NewEventCntl
  
  $routeProvider.when "/settings/adduser",
    templateUrl: "/adduser.html"
    controller: NewUserCntl

  $routeProvider.when "/settings/addopportunity",
    templateUrl: "/addopportunity.html"
    controller: AddOpportunityCntl            

  $routeProvider.when "/settings/user/edit/:userId",
    templateUrl: "/adduser.html"
    controller: EditUserCntl      

  $routeProvider.when "/settings/listusers",
    templateUrl: "/users.html"
    controller: ListUsersCntl      

  $routeProvider.when "/opp/project/edit/:projectId",
    templateUrl: "/addtitle.html"
    controller: EditProjectCntl

  $routeProvider.when "/opp/event/edit/:eventId",
    templateUrl: "/eventdetail.html"
    controller: EditEventCntl

  $locationProvider.html5Mode true

viewMod = angular.module "ngView", [ "ngResource", "dataproject", "dataopp"
                                     "dataevent", "datauser", "ui",
                                     "ui.bootstrap" ], mod

viewMod.directive "listentry", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  scope: { type : '@', display: '@', form: '@', model: '@'}
  template: '<div class="control-group">' +
            '<li ng-repeat=\"item in list\"><a href=\"/opp/data/{type}/1\">{{item.display}}</a></li>' +
            """
              <label>{{type}}</label>
              <input type="text" name="{{type}}" ng-model="themodel" required>
            </div>
            """
  link: (scope, element, attrs) ->
    #scope.typeEl = 'false' # window[scope.form][scope.type]
    scope.list = [{ display: 'test'}, {display: 'blah'}]
    scope.themodel = scope.model
    return
    #Data = $resource "/opp/data/#{scope.type}"

viewMod.directive "feed", ($resource) ->
  restrict: "E"
  replace: true
  transclude: false
  scope: {title : '@'}
  template: "<div><li ng-class=\"{doneloading: (articles.length>0)}\">Loading...</li><li ng-repeat=\"article in articles\"><a href=\"{{article.link}}\" target=\"_blank\" >{{article.title}}</a></li></div>"
  link: (scope, element, attrs) ->
    Feed = $resource "/feed/" + encodeURIComponent(attrs.url)
    scope.parentNode = element.parentNode
    scope.$on 'selpane', (ev, args) ->
      if args.title is scope.title
        console.log 'matches title'
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
      $scope.$broadcast 'selpane', { title: pane.title, pane: pane }

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
  link: (scope, element, attrs, tabsCtrl) ->
    tabsCtrl.addPane scope
  template:
    '<div class="tab-pane" ng-class="{active: selected}" ng-show="selected" ng-transclude>' +
    '</div>'
  replace: true

