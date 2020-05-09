# this file specifies the url path of the server and calls the function associated with the url


from django.urls import path
from . import views

urlpatterns = [
    path('', views.image_post, name='upload-image'),
    path('history/', views.GetMeasurements.as_view(), name='get-image'),
    path('history/<int:id>/', views.GetMeasurementsById.as_view(), name='get-image-details')
]