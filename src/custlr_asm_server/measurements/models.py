from django.db import models
from accounts.models import Account

class Image(models.Model):
    image       = models.ImageField(upload_to='images/')
    user        = models.ForeignKey(Account, on_delete=models.CASCADE)
    chest       = models.FloatField()
    shoulder    = models.FloatField()
    arm_size    = models.FloatField()
    waist       = models.FloatField()
    arm_length  = models.FloatField()