from django.urls import path
from . import views

urlpatterns = [
    # path('', views.image_post, name='upload-image'),
    path('history/', views.GetMeasurements.as_view(), name='get-image')
]