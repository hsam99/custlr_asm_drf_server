from django.urls import path
from rest_framework_jwt.views import obtain_jwt_token
from rest_auth.views import PasswordResetView, PasswordResetConfirmView, PasswordChangeView
from . import views
from django.views.generic import TemplateView
from django.conf.urls import url

urlpatterns = [
    path('signup/', views.CreateAccountView.as_view(), name='create-user'),
    path('login/', views.LoginView.as_view(), name='login'),
    url(r'^password-reset/confirm/(?P<uidb64>[0-9A-Za-z_\-]+)/(?P<token>[0-9A-Za-z]{1,13}-[0-9A-Za-z]{1,20})/$',
        TemplateView.as_view(template_name="password_reset_confirm.html"),
        name='password_reset_confirm'),
    path('password/reset/', PasswordResetView.as_view(), name='rest_password_reset'),
    path('password/reset/confirm/', PasswordResetConfirmView.as_view(), name='rest_password_reset_confirm'),
    path('password/change/', PasswordChangeView.as_view(), name='rest_password_change'),
]