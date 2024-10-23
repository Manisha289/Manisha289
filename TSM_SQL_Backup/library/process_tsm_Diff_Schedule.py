#!/usr/bin/python
 
# Copyright: (c) 2018, Terry Jones <terry.jones@example.org>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type
 
from ansible.module_utils.basic import AnsibleModule
import sys
import json
 
def create_diff_schedules(full_day, full_time):
    # Days of the week in order
    days = ['FRI', 'SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU']
    
    # Validate input
    if full_day not in days or full_time not in ['2100', '2200']:
        raise ValueError("Invalid input. Day should be FRI, SAT, or SUN and time should be 2100 or 2200.")
        
    # Find the index of the full schedule day
    start_index = days.index(full_day)
    
    # Generate differential schedules
    diff_schedules = []
    for i in range(1, 7):  # Only the next 6 days
        day = days[(start_index + i) % 7]
        schedule = f"{day}_{full_time}_DIFF_VBS"
        diff_schedules.append(schedule)
    return diff_schedules
 
def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        full_day=dict(type='str', required=True),
        full_time=dict(type='str', required=True)
    )
 
    # seed the result dict in the object
    # we primarily care about changed and state
    # changed is if this module effectively modified the target
    # state will include any data that you want your module to pass back
    # for consumption, for example, in a subsequent task
    result = dict(
        changed=False,
        diff_schedules=[]
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
        full_day = module.params['full_day']
        full_time = module.params['full_time']
        diff_schedules = create_diff_schedules(full_day, full_time)
        result['diff_schedules'] = diff_schedules
        result['changed'] = True
    except Exception as e:
        module.fail_json(msg=f"Failed to create differential schedules: {str(e)}")
 
    module.exit_json(**result)
 
def main():
    run_module()
 
if __name__ == '__main__':
    main()
