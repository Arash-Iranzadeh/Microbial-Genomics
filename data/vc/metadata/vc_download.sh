cat vc_download_link | while read r; do wget -N -P ../raw_data/ ${r}; echo $?; echo "${r} is done!"; done

