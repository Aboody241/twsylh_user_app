importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyD0fDjn2XBq35XYQoeojxJXEhN4_MG3RGg",
  authDomain: "twsylh.firebaseapp.com",
  projectId: "twsylh",
  storageBucket: "twsylh.firebasestorage.app",
  messagingSenderId: "776285847170",
  appId: "1:776285847170:web:ba81cd1ae6372830ebfe9",
  measurementId: "G-WY2PR2GM0H"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.score
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});
