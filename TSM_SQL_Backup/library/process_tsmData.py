#!/usr/bin/python

# Copyright: (c) 2018, Terry Jones <terry.jones@example.org>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.module_utils.basic import AnsibleModule
import sys
import json
 

def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        tsm_data=dict(type='dict', required=True)
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # changed is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        result_data=''
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True,
    )

    try:
        tsm_result = module.params['tsm_data']
        result_count = 1234567890
        result_server = ''
        result_value = ''


        for record in tsm_result["results"]:
            server = record['server']
            nodecount = record['count']
            flag = nodecount.isnumeric()
            if flag:
                nodecount = int(nodecount)
                if nodecount < result_count:
                  result_count = nodecount
                  result_server = server
                  ip = record['ip']
            
        if result_count != 0:
            result_value = result_server+ '&:' +str(result_count)+ '&:' +ip
        
        result['result_data'] = result_value
        result['changed'] = True
    except Exception as e:
        module.fail_json(msg=f"Failed to get tsm_result: {str(e)}")

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()#!/usr/bin/python

# Copyright: (c) 2018, Terry Jones <terry.jones@example.org>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.module_utils.basic import AnsibleModule
import sys
import json
 

def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        tsm_data=dict(type='dict', required=True)
    )

    # seed the result dict in the object
    # we primarily care about changed and state
    # changed is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        result_data=''
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True,
    )

    try:
        tsm_result = module.params['tsm_data']
        result_count = 1234567890
        result_server = ''
        result_value = ''


        for record in tsm_result["results"]:
            server = record['server']
            nodecount = record['count']
            flag = nodecount.isnumeric()
            if flag:
                nodecount = int(nodecount)
                if nodecount < result_count:
                  result_count = nodecount
                  result_server = server
                  ip = record['ip']
            
        if result_count != 0:
            result_value = result_server+ '&:' +str(result_count)+ '&:' +ip
        
        result['result_data'] = result_value
        result['changed'] = True
    except Exception as e:
        module.fail_json(msg=f"Failed to get tsm_result: {str(e)}")

    module.exit_json(**result)


def main():
    run_module()


if __name__ == '__main__':
    main()
