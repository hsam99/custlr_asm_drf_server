# this file specifies the url path of the server and calls the django apps associated with the url


from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('accounts.urls')),
    path('measurements/', include('measurements.urls')),
] +  static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
