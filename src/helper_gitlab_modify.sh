#!/bin/bash
# A file that contains functions to make modifications to GitLab
# repositories.

# run with:
#./mirror_github_to_gitlab.sh "a-t-0" "testrepo" "filler_github"

###source src/helper_dir_edit.sh
###source src/helper_github_modify.sh
###source src/helper_github_status.sh
####source src/helper_gitlab_modify.sh
###source src/helper_gitlab_status.sh
###source src/helper_git_neutral.sh
###source src/helper_ssh.sh
###source src/hardcoded_variables.txt
###source src/creds.txt
###source src/get_gitlab_server_runner_token.sh
###source src/push_repo_to_gitlab.sh

# Hardcoded data:

# Get GitHub username.
github_username=$1

# Get GitHub repository name.
github_repo=$2

# OPTIONAL: get GitHub personal access token or verify ssh access to support private repositories.
github_personal_access_code=$3

verbose=$4

# Get GitLab username.
# shellcheck disable=SC2154
gitlab_username=$(echo "$gitlab_server_account" | tr -d '\r')

# Get GitLab user password.
gitlab_server_password=$(echo "$gitlab_server_password" | tr -d '\r')

# Get GitLab personal access token from hardcoded file.
gitlab_personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')

# Specify GitLab mirror repository name.
gitlab_repo="$github_repo"

if [ "$verbose" == "TRUE" ]; then
  echo "MIRROR_LOCATION=$MIRROR_LOCATION"
  echo "github_username=$github_username"
  echo "github_repo=$github_repo"
  echo "github_personal_access_code=$github_personal_access_code"
  echo "gitlab_username=$gitlab_username"
  echo "gitlab_server_password=$gitlab_server_password"
  echo "gitlab_personal_access_token=$gitlab_personal_access_token"
  echo "gitlab_repo=$gitlab_repo"
fi

#######################################
# Deletes the repository if it doesn't exist in the GitLab server.
# Local variables:
#  deleted_repo_is_found
#  gitlab_repo_name
# Globals:
#  None.
# Arguments:
#   Name of the GitLab repository.
# Returns:
#  0 if funciton was evaluated succesfull.
#  7 if the repoaitory was not found. 
# Outputs:
#  None.
# TODO(a-t-0): change root with Global variable.
#######################################
delete_gitlab_repo_if_it_exists() {
  local gitlab_repo_name="$1"
  
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    assert_equal "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" "NOTFOUND"
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    # TODO(a-t-0): change root with Global variable.
    delete_existing_repository "$gitlab_repo_name" "root"
    sleep 5
    local deleted_repo_is_found
	deleted_repo_is_found="$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")"
    assert_equal "$deleted_repo_is_found" "NOTFOUND"
  else
    echo "The repository was not NOTFOUND, nor was it FOUND. "
    exit 7
  fi
}


#######################################
# Determines if the GitLab repository exists locally.
# Local variables:
#  gitlab_repo_name
# Globals:
#  $MIRROR_LOCATION
# Arguments:
#  The GitLab repository name.
# Returns:
#  0 if funciton was evaluated succesfull.
# Outputs:
#  FOUND if the GitLab repository exist locally in the mirror location and 
#  NOTFOUND if the GitLab repository doesn't exist there.
#######################################
gitlab_repo_exists_locally(){
  local gitlab_repo_name="$1"
  if test -d "$MIRROR_LOCATION/GitLab/$gitlab_repo_name"; then
    echo "FOUND"
  else
    echo "NOTFOUND"
  fi
}


#######################################
# Determines whether the GitLab repository name exists in the GitLab server or 
# locally. If it is not found locally, a clone of the GitLab repository is made.
# Local variables:
#  gitlab_username
#  gitlab_repo_name
#  gitlab_server_password
# Globals:
#  $MIRROR_LOCATION
#  $GITLAB_SERVER
#  $gitlab_server_account
#  $gitlab_server_password
# Arguments:
#  The GitLab username.
#  The GitLab repository name.
# Returns:
#  0 if function was evaluated succesfull.
#  8 if mirror directory was not found locally.
#  9 if GitLab repository was not found in the GitLab server.
#  10 if GitLab repoaitory was not found locally and not cloned to the mirror location. 
# Outputs:
#  FOUND if the GitLab repository exist in the GitLab server or locally in the
#  mirror location. 
#  NOTFOUND if the GitLab repository doesn't exist in the GitLab server or 
#  locally.
# TODO(a-t-0): verify local GitLab mirror repo directories are created.
# TODO(a-t-0): verify the repository exists in GitLab, throw error otherwise.
# TODO(a-t-0): do a gitlab pull to get the latest version.
# TODO(a-t-0): Capitalize $gitlab_server_account in all files.
# TODO(a-t-0): Capitalize $gitlab_server_password in all files.
#######################################
get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab() {
  local gitlab_username="$1"
  local gitlab_repo_name="$2"
  
  # Remove spaces at end of username and servername.
  local gitlab_server_password=$(echo "$gitlab_server_password" | tr -d '\r')
  
  # TODO(a-t-0): verify local gitlab mirror repo directories are created
  create_mirror_directories
  
  if [ "$(verify_mirror_directories_are_created)" != "FOUND" ]; then
    echo "ERROR, the GitLab repository was not found locally."
    exit 8
  # TODO(a-t-0): verify the repository exists in GitLab, throw error otherwise.
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    echo "ERROR, the GitLab repository was not found in the GitLab server."
    exit 9
  else
    if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "NOTFOUND" ]; then
      # shellcheck disable=SC2153
	  clone_repository "$gitlab_repo_name" "$gitlab_username" "$gitlab_server_password" "$GITLAB_SERVER" "$MIRROR_LOCATION/GitLab/"
      assert_equal "$(gitlab_repo_exists_locally "$gitlab_repo_name")" "FOUND"
      echo "FOUND"
    elif [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
      echo "FOUND"
      # TODO(a-t-0): do a gitlab pull to get the latest version.
    else
      echo "ERROR, the GitLab repository was not found locally and not cloned."
      exit 10
    fi
  fi
}

# Structure:gitlab_modify
# TODO: move to helper.
git_pull_gitlab_repo() {
  gitlab_repo_name="$1"
  if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
    
    # Get the path before executing the command (to verify it is restored correctly after).
    pwd_before="$PWD"
    
    # Do a git pull inside the gitlab repository.
    cd "$MIRROR_LOCATION/GitLab/$gitlab_repo_name" && git pull
    cd ../../..
    
    # Get the path after executing the command (to verify it is restored correctly after).
    pwd_after="$PWD"
    
    # Verify the current path is the same as it was when this function started.
    if [ "$pwd_before" != "$pwd_after" ]; then
      echo "The current path is not returned to what it originally was."
      exit 111
    fi
  else 
    echo "ERROR, the GitLab repository does not exist locally."
    exit 12
  fi
}


# Structure:gitlab_status
#6.d.1 If the GItHub branch already exists in the GItLab mirror repository does not yet exist, create it.
# source src/import.sh src/helper_gitlab_modify.sh && create_empty_repository_v0 "sponsor_example" "root"
##run bash -c "source src/import.sh src/helper_gitlab_modify.sh && create_empty_repository_v0 sponsor_example root"
create_empty_repository_v0() {
  gitlab_repo_name="$1"
  gitlab_username="$2"
   
   # load personal_access_token (from hardcoded data)
    personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')
  
  # TODO: Check if GitLab server is running
  
  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
  
    # If it already exists, delete the repository
    delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
    sleep 30
    
    # Verify the repository is deleted.
    if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
      # Throw an error if it is not deleted.
      echo "The GitLab repository was supposed to be deleted, yet it still exists."
      #exit 177
    fi
  fi
  
  # Create repository.
  curl -H "Content-Type:application/json" "$GITLAB_SERVER_HTTP_URL/api/v4/projects?private_token=$personal_access_token" -d "{ \"name\": \"$gitlab_repo_name\" }"
  sleep 30
  
  
  # Verify the repository is created.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "FOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet exists."
    exit 178
  fi
  
}

create_gitlab_repository_if_not_exists() {
  gitlab_repo_name="$1"
  gitlab_username="$2"
  
  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    create_empty_repository_v0 "$gitlab_repo_name" "$gitlab_username"
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    echo ""
  else
    echo "ERROR, the GitLab repository: $gitlab_repo_name is not found, nor is it determined that it does not exist."
    exit 179
  fi
  
  # Verify the repository exists.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "FOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet exists."
    exit 180
  fi
}

delete_gitlab_repository_if_it_exists() {
  gitlab_repo_name="$1"
  gitlab_username="$2"
  
  # Check if repository already exists in GitLab server.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "NOTFOUND" ]; then
    echo ""
  elif [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" == "FOUND" ]; then
    # If it exists, delete the repository.
    delete_existing_repository "$gitlab_repo_name" "$gitlab_username"
    sleep 30
  else
    echo "ERROR, the GitLab repository: $gitlab_repo_name is not found, nor is it determined that it does not exist."
    exit 181
  fi
  
  # Verify the repository does not exists.
  if [ "$(gitlab_mirror_repo_exists_in_gitlab "$gitlab_repo_name")" != "NOTFOUND" ]; then
    # Throw an error if it is not created succesfully.
    echo "The GitLab repository was supposed to be created, yet it does not yet exists."
    exit 182
  fi
}


# Structure:gitlab_modify
#source src/import.sh src/helper_gitlab_modify.sh && delete_existing_repository "sponsor_example" "root"
delete_existing_repository() {
  repo_name="$1"
  repo_username="$2"
  
  # load personal_access_token
  personal_access_token=$(echo "$GITLAB_PERSONAL_ACCESS_TOKEN" | tr -d '\r')
  
  #curl -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE "$GITLAB_SERVER_HTTP_URL"/api/v4/projects/"$repo_username"%2F"$repo_name"
  output=$(curl -H 'Content-Type: application/json' -H "Private-Token: $personal_access_token" -X DELETE "$GITLAB_SERVER_HTTP_URL"/api/v4/projects/"$repo_username"%2F"$repo_name")
  
  if [  "$(lines_contain_string '{"message":"404 Project Not Found"}' "\${output}")" == "FOUND" ]; then
    echo "ERROR, you tried to delete a GitLab repository that does not exist."
    exit 183
  fi
}

# Structure:gitlab_modify
#source src/run_ci_job.sh && clone_repository
# TODO: rename to clone_gitlab_repository_from _local_server
clone_repository() {
  repo_name=$1
  gitlab_username=$2
  gitlab_server_password=$3
  gitlab_server=$4
  target_directory=$5
  
  # TODO:write test to verify the gitlab username and server don't end with a spacebar character.  
  
  # Clone the GitLab repository into the GitLab mirror storage location.
  output=$(cd "$target_directory" && git clone http://$gitlab_username:$gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
}

# Structure:gitlab_modify
# 6.f.0 Checkout that branch in the local GitHub mirror repository.
checkout_branch_in_github_repo() {
  local github_repo_name="$1"
  local github_branch_name="$2"
  local company="$3"
  
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

    # Verify the branch exists
    branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
    if [ "$last_line_branch_check_result" == "FOUND" ]; then
    
      # Get the path before executing the command (to verify it is restored correctly after).
      pwd_before="$PWD"
      
      # Checkout the branch inside the repository.
      cd "$MIRROR_LOCATION/$company/$github_repo_name" && git checkout "$github_branch_name"
      cd ../../../..
      # Get the path after executing the command (to verify it is restored correctly after).
      pwd_after="$PWD"
  
      # Test to verify the current branch in the GitHub repository is indeed checked out.
      # TODO: check if this passes
      assert_current_github_branch "$github_repo_name" "$github_branch_name"
      
      
      # Verify the current path is the same as it was when this function started.
      if [ "$pwd_before" != "$pwd_after" ]; then
        echo "The current path is not returned to what it originally was."
        #echo "pwd_before=$pwd_before"
        #echo "pwd_after=$pwd_after"
        exit 15
      fi
    else 
      echo "ERROR, the GitHub branch does not exist locally."
      exit 16
    fi
  else 
    echo "ERROR, the GitHub repository does not exist locally."
    exit 172
  fi
}

# Structure:gitlab_modify
# assumes you cloned the gitlab branch: 6.e.0 get_gitlab_repo_if_not_exists_locally_and_exists_in_gitlab
# 6.h.1 Checkout that branch in the local GitLab mirror repository if it exists.
# 6.h.2 If the branch does not exist in the GitLab repo, create it.
# 6.h.0 Checkout that branch in the local GitLab mirror repository. (Assuming the GitHub branch contains a gitlab yaml file)
checkout_branch_in_gitlab_repo() {
  gitlab_repo_name="$1"
  gitlab_branch_name="$2"
  company="$3"
  
  if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then

    # Verify the desired branch exists.
    branch_check_result="$(gitlab_branch_exists $gitlab_repo_name $gitlab_branch_name)"
    last_line_branch_check_result=$(get_last_line_of_set_of_lines "\${branch_check_result}")
    found_branch_name="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")"
    if [ "$last_line_branch_check_result" == "FOUND" ]; then
    
      # Get the path before executing the command (to verify it is restored correctly after).
      pwd_before="$PWD"
      
      # Checkout the branch inside the repository.
      cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout "$gitlab_branch_name"
      cd ../../../..
      
      # Get the path after executing the command (to verify it is restored correctly after).
      pwd_after="$PWD"
  
      # Verify the current branch in the gitlab repository is indeed checked out.
      # e.g. using git status
      assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"
      
    else 
      # Get the path before executing the command (to verify it is restored correctly after).
      pwd_before="$PWD"
      
      # Create the branch.
      cd "$MIRROR_LOCATION/$company/$gitlab_repo_name" && git checkout -b "$gitlab_branch_name"
      cd ../../../..
      # Get the path after executing the command (to verify it is restored correctly after).
      pwd_after="$PWD"
      
      # Verify the current branch in the gitlab repository is indeed checked out.
      # TODO: Check if this passes.
      assert_current_gitlab_branch "$gitlab_repo_name" "$gitlab_branch_name"
    fi
    
    # Verify the current path is the same as it was when this function started.
    path_before_equals_path_after_command "$pwd_before" "$pwd_after"
  else 
    echo "ERROR, the gitlab repository does not exist locally."
    exit 20
  fi
}

# Structure:gitlab_modify
push_changes() {
  repo_name=$1
  gitlab_username=$2
  gitlab_server_password=$3
  gitlab_server=$4
  target_directory=$5
  
  output=$(cd "$target_directory" && git push http://$gitlab_username:$gitlab_server_password@$gitlab_server/$gitlab_username/$repo_name.git)
}

# Structure:gitlab_modify
# source src/run_ci_job.sh && export_repo
# Write function that exportis the test-repository to a separate external folder.
delete_target_folder() {
  # check if target folder already exists
  # delete target folder if it already exists
  if [ -d "../$SOURCE_FOLDERNAME" ] ; then
      sudo rm -r "../$SOURCE_FOLDERNAME"
  fi
  # create target folder
  # copy source folder to target
}

#TODO:
# Structure:gitlab_modify
# 6.k Commit the GitLab branch changes, with the sha from the GitHub branch.
commit_changes_to_gitlab() {
  github_repo_name="$1"
  github_branch_name="$2"
  github_commit_sha="$3"
  gitlab_repo_name="$4"
  gitlab_branch_name="$5"
  
  # If the GitHub repository exists
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

    # If the GitHub branch exists
    github_branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    last_line_github_branch_check_result=$(get_last_line_of_set_of_lines "\${github_branch_check_result}")
    if [ "$last_line_github_branch_check_result" == "FOUND" ]; then
    
      # If the GitHub branch contains a gitlab yaml file
      filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
      if [ "$(file_exists $filepath)" == "FOUND" ]; then
        
        # If the GitLab repository exists
        if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
          
          # If the GitLab branch exists
          found_branch_name="$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")"
          if [ "$found_branch_name" == "$gitlab_branch_name" ]; then
          
            # If there exist differences in the files or folders in the branch (excluding the .git directory)
            
            # Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
            # That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
            copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"
            
            # Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
            comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"
            
            # Verify the files were correctly copied from GitHub branch to GitLab branch.
            if [ "$comparison_result" == "IDENTICAL" ]; then
              #echo "IDENTICAL"
              
              # Get the path before executing the command (to verify it is restored correctly after).
              pwd_before="$PWD"
              
              if [[ "$(git_has_changes "$MIRROR_LOCATION/GitLab/$github_repo_name")" == "FOUND" ]]; then
              
                # Commit the changes to GitLab.
                cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git add -A && git commit -m \"$github_commit_sha\"
                cd ../../../..
              fi
              
              # Get the path after executing the command (to verify it is restored correctly after).
              pwd_after="$PWD"
              
              # Verify the current path is the same as it was when this function started.
              path_before_equals_path_after_command "$pwd_before" "$pwd_after"
              
              # TODO: Verify the changes were committed to GitLab correctly. (There are no remaining files to be added)
              #git status
              # TODO: Verify the changes were committed to GitLab correctly. (There commit message equals the sha)
              #git log
              
            else
              echo "ERROR, the content in the GitHub branch is not exactly copied into the GitLab branch, even when excluding the .git directory."
              exit 11
            fi
            
          else
            echo "ERROR, the GitLab branch does not exist locally."
            exit 12
          fi
        else
          echo "ERROR, the GitLab repository does not exist locally."
          exit 13
        fi
      else
        echo "ERROR, the GitHub branch does contain a yaml file."
        exit 14
      fi
    else 
      echo "ERROR, the GitHub branch does not exist locally."
      exit 24
    fi
  else 
    echo "ERROR, the GitHub repository does not exist locally."
    exit 25
  fi
}



#TODO:
# Structure:gitlab_modify
# 6.l Push the GitLab branch changes.
push_changes_to_gitlab() {
  # Verify the GitLab repo was downloaded.
  # Verify the GitLab branch was checked out.
  
  # Verify the GitLab repo was downloaded.
  # Verify the GitLab branch was checked out.
  
  # Verify the files were correctly copied from GitHub branch to GitLab branch.
  
  # Verify the changes were committed to GitLab correctly.
  
  # Push the changes to GitLab.
  
  # Verify the changes were pushed to GitLab correctly.
  github_repo_name="$1"
  github_branch_name="$2"
  github_commit_sha="$3"
  gitlab_repo_name="$4"
  gitlab_branch_name="$5"
  
  # If the GitHub repository exists
  if [ "$(github_repo_exists_locally "$github_repo_name")" == "FOUND" ]; then

    # If the GitHub branch exists
    github_branch_check_result="$(github_branch_exists $github_repo_name $github_branch_name)"
    last_line_github_branch_check_result=$(get_last_line_of_set_of_lines "\${github_branch_check_result}")
    if [ "$last_line_github_branch_check_result" == "FOUND" ]; then
    
      # If the GitHub branch contains a gitlab yaml file
      filepath="$MIRROR_LOCATION/GitHub/$github_repo_name/.gitlab-ci.yml"
      if [ "$(file_exists $filepath)" == "FOUND" ]; then
        
        # If the GitLab repository exists
        if [ "$(gitlab_repo_exists_locally "$gitlab_repo_name")" == "FOUND" ]; then
          
          # If the GitLab branch exists
          
          found_branch_name=$(get_current_gitlab_branch $gitlab_repo_name $gitlab_branch_name "GitLab")
          if [ "$found_branch_name" == "$gitlab_branch_name" ]; then
          
            # If there exist differences in the files or folders in the branch (excluding the .git directory)
            
            # Then copy the files and folders from the GitHub branch into the GitLab branch (excluding the .git directory)
            # That also deletes the files that exist in the GitLab branch that do not exist in the GitHub branch (excluding the .git directory)
            copy_github_files_and_folders_to_gitlab "$MIRROR_LOCATION/GitHub/$github_repo_name" "$MIRROR_LOCATION/GitLab/$github_repo_name"
            
            # Then verify the checksum of the files and folders in the branches are identical (excluding the .git directory)
            comparison_result="$(two_folders_are_identical_excluding_subdir $MIRROR_LOCATION/GitHub/$github_repo_name $MIRROR_LOCATION/GitLab/$github_repo_name .git)"
            
            # Verify the files were correctly copied from GitHub branch to GitLab branch.
            if [ "$comparison_result" == "IDENTICAL" ]; then
              #echo "IDENTICAL"
              
              # Get the path before executing the command (to verify it is restored correctly after).
              pwd_before="$PWD"
              
              # TODO: Verify the changes were committed to GitLab correctly. (There are no remaining files to be added)
              #git status
              # TODO: Verify the changes were committed to GitLab correctly. (There commit message equals the sha)
              #git log
              
              # Commit the changes to GitLab.
              cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git push --set-upstream origin "$gitlab_branch_name"
              #cd "$MIRROR_LOCATION/GitLab/$github_repo_name" && git push --set-upstream origin main
              cd ../../../..
              
              # Get the path after executing the command (to verify it is restored correctly after).
              pwd_after="$PWD"
              
              # Verify the current path is the same as it was when this function started.
              path_before_equals_path_after_command "$pwd_before" "$pwd_after"
              
            else
              echo "ERROR, the content in the GitHub branch is not exactly copied into the GitLab branch, even when excluding the .git directory."
              exit 11
            fi
            
          else
            echo "ERROR, the GitLab branch does not exist locally."
            exit 12
          fi
        else
          echo "ERROR, the GitLab repository does not exist locally."
          exit 13
        fi
      else
        echo "ERROR, the GitHub branch does contain a yaml file."
        exit 14
      fi
    else 
      echo "ERROR, the GitHub branch does not exist locally."
      exit 24
    fi
  else 
    echo "ERROR, the GitHub repository does not exist locally."
    exit 25
  fi
}