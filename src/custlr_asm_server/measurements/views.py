from django.shortcuts import render
# import Custlr_ASM_Server_Front_v2 as custlr_asm
from django.http import HttpResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.decorators import parser_classes
from rest_framework.parsers import JSONParser, MultiPartParser
from .serializers import ImageSerializer, MeasurementSerializer
from .models import Image
from rest_framework.views import APIView
from datetime import datetime
from django.core.files import File
import os


# matlab engine api
import matlab.engine
def asm_model(image_path, image_instance):
    eng = matlab.engine.start_matlab()
    eng.cd(r'.\matlab')
    try:
        image_landmark, ans = eng.Custlr_ASM_Server_Front_v2(image_path, nargout=2)

    except Exception as e:
        print(e)
        ans = -1
        image_landmark = None
        image_instance.delete()
    eng.close()
    return image_landmark, ans

# calls matlab function with image path
# def asm_model(image_path, image_instance):
#     init = custlr_asm.initialize()
#     try:
#         ans = init.Custlr_ASM_Server_Front_v2(image_path)
#     except:
#         ans = -1
#         image_instance.delete()
#     custlr_asm.__exit_packages()
#     return ans


def split_measurement(measurement_str):
    measurements = []
    temp = measurement_str.split('\n')
    
    for i in range(1,6):
        measurements.append(round(float(temp[i].split(": ")[1]), 2))

    return measurements


@api_view(['POST'])
@parser_classes([JSONParser, MultiPartParser])
def image_post(request, format=None):
    uri = request.build_absolute_uri()
    url = uri.rsplit('/', 2)[0]
    if request.FILES:
        data = request.FILES
        image_serializer = ImageSerializer(data=data)

        if image_serializer.is_valid():
            image_instance = image_serializer.save(user=request.user, chest=0, shoulder=0,
                                  arm_size=0, waist=0, arm_length=0, date_created=datetime.now())
            image_path = '..' + str(image_serializer.data['image'])

            # image_path for matlab custlr library
            # image_path = '.' + str(image_serializer.data['image'])
            image_landmark, measurements = asm_model(image_path, image_instance)

            if measurements == -1:
                return Response({'error': 'The system is unable to process the image. Please try again.'}, 
                                    status=status.HTTP_422_UNPROCESSABLE_ENTITY)
                                
            cleaned_measurements = split_measurement(measurements)
            image_instance.chest = cleaned_measurements[0]
            image_instance.shoulder = cleaned_measurements[1]
            image_instance.arm_size = cleaned_measurements[2] 
            image_instance.waist = cleaned_measurements[3] 
            image_instance.arm_length = cleaned_measurements[4]
            image_instance.image_landmark.save(os.path.basename(image_landmark), File(open(image_landmark, 'rb')))
            image_instance.save()

            landmark_image_url = url + r'/media/images/' + os.path.basename(image_landmark)
            original_image_url = url + str(image_serializer.data['image'])

            return Response({"chest": cleaned_measurements[0], 
                            "shoulder": cleaned_measurements[1],
                            "arm_size": cleaned_measurements[2],
                            "waist": cleaned_measurements[3],
                            "arm_length": cleaned_measurements[4],
                            "landmark_image_url": landmark_image_url,
                            "original_image_url": original_image_url,
            }, status=status.HTTP_201_CREATED)

        else:
            return Response(image_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    else:
        return Response({'message': 'Image not found'}, status=status.HTTP_400_BAD_REQUEST)


class GetMeasurements(APIView):
    def get(self, request, format=None):
        measurements = Image.objects.filter(user=request.user)
        serializer = MeasurementSerializer(measurements, many=True)
        return Response(serializer.data)
