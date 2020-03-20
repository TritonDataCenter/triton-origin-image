/*
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

/*
 * Copyright 2020 Joyent, Inc.
 */

@Library('jenkins-joylib@v1.0.4') _

pipeline {

    agent none

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
    }
    parameters {
        booleanParam(
            name: 'BUILD_15_4_1',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-multiarch-15.4.1'
        )
        booleanParam(
            name: 'BUILD_18_1_0',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-multiarch-18.1.0'
        )
        booleanParam(
            name: 'BUILD_18_4_0',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-x86_64-18.4.0'
        )
        booleanParam(
            name: 'BUILD_19_1_0',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-x86_64-19.1.0'
        )
        booleanParam(
            name: 'BUILD_19_2_0',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-x86_64-19.2.0'
        )
        booleanParam(
            name: 'BUILD_19_4_0',
            defaultValue: false,
            description: 'This parameter declares whether to build ' +
                'triton-origin-x86_64-19.4.0'
        )
    }
    stages {
        stage('triton-origin-multiarch-15.4.1') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '15.4.1')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_15_4_1', value: 'true'
            }
            steps {
                sh('''
export TRACE=1

set -o errexit
set -o pipefail
make clean distclean
export UPDATES_IMGADM_CHANNEL=experimental
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-multiarch-15.4.1-"buildimage bits-upload"
''')
            }
        }
        stage('triton-origin-multiarch-18.1.0') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '18.1.0')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_18_1_0', value: 'true'
            }
            steps {
                sh('''
export TRACE=1

set -o errexit
set -o pipefail
make clean distclean
export UPDATES_IMGADM_CHANNEL=experimental
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-multiarch-18.1.0-"buildimage bits-upload"
    ''')
            }
        }
        stage('triton-origin-x86_64-18.4.0') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '18.4.0')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_18_4_0', value: 'true'
            }
            steps {
                sh('''
export TRACE=1

set -o errexit
set -o pipefail
make clean distclean
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-x86_64-18.4.0-"buildimage bits-upload"
''')
            }
        }
        stage('triton-origin-image-x86_64-19.1.0') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '19.1.0')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_19_1_0', value: 'true'
            }
            steps {
                sh('''
export TRACE=1
set -o errexit
set -o pipefail
make clean distclean
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-x86_64-19.1.0-"buildimage bits-upload"
''')
            }
        }
        stage('triton-origin-image-x86_64-19.2.0') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '19.2.0')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_19_2_0', value: 'true'
            }
            steps {
                sh('''
export TRACE=1
set -o errexit
set -o pipefail
make clean distclean
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-x86_64-19.2.0-"buildimage bits-upload"
''')
            }
        }
        stage('triton-origin-image-x86_64-19.4.0') {
            agent {
                node {
                    label joyCommonLabels(image_ver: '19.4.0')
                }
            }
            when {
                beforeAgent true
                environment name: 'BUILD_19_4_0', value: 'true'
            }
            steps {
                sh('''
export TRACE=1
set -o errexit
set -o pipefail
make clean distclean
export ENGBLD_BITS_UPLOAD_IMGAPI=true
make print-BRANCH print-STAMP triton-origin-x86_64-19.4.0-"buildimage bits-upload"
''')
            }
        }
    }

    post {
        always {
            joyMattermostNotification()
        }
    }
}
