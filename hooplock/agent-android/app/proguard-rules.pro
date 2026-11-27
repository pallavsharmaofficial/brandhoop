# Components referenced from the manifest are kept by AGP. Keep receivers/services names stable
# because the provisioning QR names the admin receiver.
-keep class in.hooplock.agent.admin.HoopAdminReceiver { *; }
