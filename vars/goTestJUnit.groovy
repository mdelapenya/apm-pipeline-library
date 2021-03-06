// Licensed to Elasticsearch B.V. under one or more contributor
// license agreements. See the NOTICE file distributed with
// this work for additional information regarding copyright
// ownership. Elasticsearch B.V. licenses this file to you under
// the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

/**
 Run Go unit tests and generate a JUnit report.

 goTestJUnit(options: '-v ./...', output: 'build/junit-report.xml')
*/
def call(Map args = [:]) {
  def options = args.containsKey('options') ? args.options : ''
  def output = args.containsKey('output') ? args.output : 'junit-report.xml'
  def version = args.containsKey('version') ? args.version : goDefaultVersion()

  log(level: 'INFO', text: 'Running Go test an generating JUnit output')

  withGoEnv(version: version, pkgs: ["gotest.tools/gotestsum"]){
    cmd(label: 'Running Go tests' , script: "gotestsum --format testname --junitfile ${output} -- ${options}")
  }
}
