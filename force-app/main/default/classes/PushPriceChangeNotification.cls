public with sharing class PushPriceChangeNotification {
    @InvocableMethod(label='Push Price Change Notification')
    public static void pushNotification(List<Id> propertyId) {
        String pushServerURL;
        Dreamhouse_Settings__c settings = Dreamhouse_Settings__c.getOrgDefaults();
        if (!Test.isRunningTest()) {
            if (settings == null || settings.Push_Server_URL__c == null) {
                System.debug(
                    'Push_Server_URL not set. Aborting PushPriceChangeNotification process action'
                );
                return;
            } else {
                pushServerURL = settings.Push_Server_URL__c;
            }
        }
        Id propId = propertyId[0]; // If bulk, only post first to avoid spamming
        Property__c property = [
            SELECT Name, Price__c
            FROM Property__c
            WHERE Id = :propId
            WITH SECURITY_ENFORCED
        ];
        String message =
            property.Name +
            '. New Price: $' +
            property.Price__c.setScale(0).format();

        Set<String> userIds = new Set<String>();

        List<Property_Favorite__c> favorites = [
            SELECT user__c
            FROM Property_Favorite__c
            WHERE property__c = :propId
            WITH SECURITY_ENFORCED
        ];
        for (Property_Favorite__c favorite : favorites) {
            userIds.add(favorite.user__c);
        }

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('message', message);
        payload.put('userIds', userIds);
        String body = JSON.serialize(payload);
        System.enqueueJob(new QueueablePushCall(pushServerURL, 'POST', body));
    }

    public class QueueablePushCall implements System.Queueable, Database.AllowsCallouts {
        private final String url;
        private final String method;
        private final String body;

        public QueueablePushCall(String url, String method, String body) {
            this.url = url;
            this.method = method;
            this.body = body;
        }

        public void execute(System.QueueableContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setMethod(method);
            req.setHeader('Content-Type', 'application/json');
            req.setBody(body);
            Http http = new Http();
            HttpResponse res;
            if (!Test.isRunningTest()) {
                req.setEndpoint(url);
                res = http.send(req);
            }
        }
    }
}