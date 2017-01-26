minion_setup:
  salt.state:
    - tgt: 'roles:minion'
    - tgt_type: grain
    - highstate: True
