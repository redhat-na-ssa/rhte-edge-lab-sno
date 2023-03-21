# Edge Lab - SNO

## To develop using Red Hat Dev Spaces

[![Contribute](https://www.eclipse.org/che/contribute.svg)](https://workspaces.openshift.com#https://github.com/redhat-na-ssa/rhte-edge-lab-sno)

Click the above badge

### Using the `live preview` functionality
1. Once the workspace loads, expand the `endpoints` drop-down
    1. It may take a few seconds to load
2. Click on the clipboard image to the right of `jekyll-server (8080/http)`
3. Paste the URL into another tab
> **Note**
>
> You may need to refresh the page to see your changes

### Run tasks in the Jekyll container
1. Press `[CTRL]`+`[SHIFT]`+`[P]`
2. Type `create new terminal`
3. Select `Terminal: Create New Terminal to DevWorkspace Container`
4. A new terminal will be created using the Jekyll container

### Using the Universal Developer Image to interact with Git
1. Press `[CTRL]`+`[SHIFT]`+`[~]`
2. Use git as you normally would
> **Note**
>
> To use tab completion, `source /usr/share/bash-completion/completions/git`
>
> You can also create a config map which creates a `.bashrc` file for you, and sources this automatically.