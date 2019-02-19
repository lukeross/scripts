#!/usr/bin/env python3

from setuptools import setup

setup(
    name='Werkzeug-FormatStringRouting',
    version='0.1',
    url='https://lukeross.name/projects/scripts/',
    license='BSD',
    author='Luke Ross',
    author_email='luke@lukeross.name',
    description='Very short description',
    packages=['werkzeug_formatstringrouting'],
    include_package_data=True,
    platforms='any',
    install_requires=[
        'parse',
        'Werkzeug',
    ],
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Web Environment',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content',
        'Topic :: Software Development :: Libraries :: Python Modules'
    ]
)

