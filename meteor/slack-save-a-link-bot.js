Links = new Meteor.Collection("links", {idGeneration : 'MONGO'});
Links.allow({
  insert: function(){
    return true;
  },
  update: function () {
    return true;
  },
  remove: function(){
    return true;
  }
});


if (Meteor.isClient) {
    // counter starts at 0
    Session.setDefault("counter", 0);

    Template.hello.helpers({
        linkList: function () {
            return Links.find();
        },
        counter: function () {
            return Session.get("counter");
        }
    });

    Template.hello.events({
        'click button': function () {
            // increment the counter when button is clicked
            Session.set("counter", Session.get("counter") + 1);
        }
    });
}

var token = Meteor.settings.slack_token;//process.env.SLACK_TOKEN

Router.route('/');

Router.route('/api/v1/links', {where: 'server'})
    .post(function () {
        if (_.isUndefined(this.request.body.token)
            || _.isUndefined(token)
            || this.request.body.token != token) {
            console.log("Un-authorized request");
            this.response.statusCode = 404;
            this.response.end();
        } else {
            console.log("Authorized request");
            this.response.statusCode = 200;
            this.response.setHeader("Content-Type", "application/json");
            this.response.setHeader("Access-Control-Allow-Origin", "*");
            this.response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
            var user = this.request.body.user_name
            var text = this.request.body.text;
            var trig = this.request.body.trigger_word
            var link = text.replace(trig, "").trim()
            var rslt = new Object();
            rslt.text = link
            Links.insert(rslt);
            this.response.end('{ "text": "Yes, ' + user + '! Link: '+ link  + ' was saved" }');
        }
    })
    .get(function(){
        this.response.statusCode = 200;
        this.response.setHeader("Content-Type", "application/json");
        this.response.setHeader("Access-Control-Allow-Origin", "*");
        this.response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        this.response.end(JSON.stringify(
            Links.find().fetch()
        ));
    });


/**
 * Debug-only, to be able to see what exactly webhooks are sending
 * Intended use like {@code curl -X POST localhost:3000/api/v1/dump -H 'Content-Type: application/json' -d '{"text":"test3"}' | jq '. | del(.socket)' }
 * Uses JSON.stringify with custom replacer
 * http://stackoverflow.com/questions/11616630/json-stringify-avoid-typeerror-converting-circular-structure-to-json/11616993#11616993
 */
Router.route('/api/v1/dump', {where: 'server'})
    .post(function () {
        this.response.statusCode = 200;
        this.response.setHeader("Content-Type", "application/json");
        this.response.setHeader("Access-Control-Allow-Origin", "*");
        this.response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        var cache = [];
        var r = JSON.stringify(this.request, function(key, value) {
            if (typeof value === 'object' && value !== null) {
                if (cache.indexOf(value) !== -1) {
                    return; // Circular reference found, discard key
                }
                cache.push(value); // Store value in our collection
            }
            return value;
        });
        console.log(r);
        this.response.end('{ "text": "Well-dumped!"}');
        cache = null;
    });
