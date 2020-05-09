# the function for this file is to create models related to user accounts in the database


from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager

class AccountManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, email, username, password=None):
        if not email:
            raise ValueError("Email is required.")
        if not username:
            raise ValueError("Username is required.")
        
        user = self.model(
                email=self.normalize_email(email),
                username=username
        )

        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, email, password):
        user = self.create_user(
            email,
            password=password,
        )
        user.is_admin = True
        user.save(using=self._db)
        return user


class Account(AbstractBaseUser):
    email           = models.EmailField(verbose_name='email', unique=True)
    username        = models.CharField(max_length=25, unique=True)
    is_active       = models.BooleanField(default=True)
    last_login      = models.DateTimeField(verbose_name='last login', auto_now_add=True)
    date_joined     = models.DateTimeField(verbose_name='date joined', auto_now_add=True)
    is_admin        = models.BooleanField(default=False)

    USERNAME_FIELD  = 'username'
    EMAIL_FIELD     = 'email'
    REQUIRED_FIELDS = []

    objects = AccountManager()

    class Meta:
        verbose_name = ('account')
        verbose_name_plural = ('accounts')

    @property
    def is_staff(self):
        return self.is_admin

    def __str__(self):
        return self.username
    

    

