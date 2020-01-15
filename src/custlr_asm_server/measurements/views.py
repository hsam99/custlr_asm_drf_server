from django.shortcuts import render
import matlab.engine
from django.http import HttpResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.decorators import parser_classes
from rest_framework.parsers import JSONParser, MultiPartParser
from .serializers import ImageSerializer
from .models import Image

# calls matlab function with image path
def asm_model(image_path):
    eng = matlab.engine.start_matlab()
    eng.cd(r'.\matlab')
    ans = eng.Custlr_ASM_Server_Front_v2(image_path)
    eng.close()
    return ans


def split_measurement(measurement_str):
    measurements = []
    temp = measurement_str.split('\n')
    
    for i in range(1,6):
        measurements.append(float(temp[i].split(": ")[1]))

    return measurements


@api_view(['GET', 'POST'])
@parser_classes([JSONParser, MultiPartParser])
def image_post(request, format=None):
    if request.FILES:
        data = request.FILES
        image_serializer = ImageSerializer(data=data)

        if image_serializer.is_valid():
            image_instance = image_serializer.save(user=request.user, chest=0, shoulder=0,
                                  arm_size=0, waist=0, arm_length=0)
            image_path = '..' + str(image_serializer.data['image'])
            print(image_path)
            measurements = asm_model(image_path)
            cleaned_measurements = split_measurement(measurements)
            image_instance.chest = chest=cleaned_measurements[0]
            image_instance.shoulder = cleaned_measurements[1]
            image_instance.arm_size = cleaned_measurements[2] 
            image_instance.waist = cleaned_measurements[3] 
            image_instance.arm_length = cleaned_measurements[4]
            image_instance.save()

            return Response(measurements, status=status.HTTP_201_CREATED)

        else:
            return Response(image_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # else:
    #     return Response({'message': 'Image not found'}, status=status.HTTP_400_BAD_REQUEST)

    #test for get request
    if request.method == 'GET':
        image = Image.objects.last()
        if image:
            image_path = '/media/' + str(image.image)
            html = "<html><body><img src='%s'/></body></html>" % image_path
            return HttpResponse(html)
        else:
            return Response({'message': 'No images found'})
