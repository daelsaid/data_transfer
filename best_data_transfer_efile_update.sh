#!/bin/bash
#author: daelsaid, 08/08/2018;
#best fmri data organization  workflow 
#fmri struct generation + reorientation, dicom efile, and exam dir organization


source ~/.bash_profile

export SPM8DIR="/Applications/spm8_sge"
export PATH=$PATH:/Volumes/Smurf-Village/SoftwareRepository/etkinlab/Stanford-EtkinLab-bitbucket/analysis_pipeline/
export PATH=$PATH:/Volumes/Smurf-Village/Imaging/best_ptsd/scripts/fmri
export PATH=$PATH:/Volumes/Smurf-Village/SoftwareRepository/linux_openmp_64/
export PATH=$PATH:/Volumes/Smurf-Village/Imaging/best_ptsd/data/mri/new/scripts

main_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd';
eeg_fmri_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/eeg_fmri/hc';
fmri_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/fmri/patient';
fmri_raw_hv='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/fmri/hv';
best_data_output_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data/new';
best_village='/Volumes/Smurf-Village/Imaging/best_ptsd';
fmri_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data/mri/new/';
eeg_fmri_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data/mri/new/';
structs='/Volumes/Smurf-Village/Imaging/best_ptsd/data/mri/new/structs';
topup='/Volumes/Smurf-Village/Imaging/best_ptsd/data/mri/new/scripts';

cd ${main_raw_dir};



function find_exams_to_organize() {
    #author: daelsaid, 08/08/2018;
    cd ${main_raw_dir};
    exams_to_organize=`find ${eeg_fmri_raw_dir}/ ${fmri_raw_dir}/ ${fmri_raw_hv}/ -maxdepth 3 -name 'E?????'`
    echo $exams_to_organize;
}

function find_exams_to_organize() {
    #author: daelsaid, 08/08/2018;
    cd ${main_raw_dir};
    exams_to_organize=`find ${eeg_fmri_raw_dir}/ ${fmri_raw_dir}/ ${fmri_raw_hv}/ -maxdepth 3 -name 'E?????'`
    echo $exams_to_organize;
}

function empty_dir() { 
    #author: daelsaid, 08/08/2018;
  if [ "$(ls -A $1)" ]; then
    echo "dir_has_data"
  else
    rm -rf $1
  fi
}


function best_struct_fslswapdim () {
    #author: rnwright
    nii=$1
    for image in `ls ${nii} | sort`
    do
        orientation=`mri_info ${image} | grep Orientation | awk -F ' ' '{ print $3 }'`
    	echo $orientation
    	if [[ $orientation == *"L"* ]]
    	then
    		placement_L=`echo $orientation | grep -aob 'L' | grep -oE '[0-9]+'`
    		if [ "$placement_L" -eq "0" ]
    		then
    			first="-x"
    		elif [ "$placement_L" -eq "1" ]
    		then
    			first="-y"
    		elif [ "$placement_L" -eq "2" ]
    		then
    			first="-z"
    		fi
    	fi
    	if [[ $orientation == *"R"* ]]
            then
    		placement_R=`echo $orientation | grep -aob 'R' | grep -oE '[0-9]+'`
                    if [ "$placement_R" -eq "0" ]
                    then
                            first="x"
                    elif [ "$placement_R" -eq "1" ]
                    then
                            first="y"
                    elif [ "$placement_R" -eq "2" ]
                    then
    			first="z"
    		fi
    	fi
    	if [[ $orientation == *"A"* ]]
            then
    		placement_A=`echo $orientation | grep -aob 'A' | grep -oE '[0-9]+'`
                    if [ "$placement_A" -eq "0" ]
                    then
                            second="x"
                    elif [ "$placement_A" -eq "1" ]
                    then
                            second="y"
                    elif [ "$placement_R" -eq "2" ]
                    then
                            second="z"
    		fi
    	fi
    	if [[ $orientation == *"P"* ]]
            then
                    placement_P=`echo $orientation | grep -aob 'P' | grep -oE '[0-9]+'`
                    if [ "$placement_P" -eq "0" ]
                    then
                            second="-x"
                    elif [ "$placement_P" -eq "1" ]
                    then
                            second="-y"
                    elif [ "$placement_P" -eq "2" ]
                    then
                            second="-z"
                    fi
    	fi
    	if [[ $orientation == *"S"* ]]
            then
                    placement_S=`echo $orientation | grep -aob 'S' | grep -oE '[0-9]+'`
                    if [ "$placement_S" -eq "0" ]
                    then
                            third="x"
                    elif [ "$placement_S" -eq "1" ]
                    then
                            third="y"
                    elif [ "$placement_S" -eq "2" ]
                    then
                            third="z"
                    fi
    	fi
    	if [[ $orientation == *"I"* ]]
            then
                    placement_I=`echo $orientation | grep -aob 'I' | grep -oE '[0-9]+'`
                    if [ "$placement_I" -eq "0" ]
                    then
                            third="-x"
                    elif [ "$placement_I" -eq "1" ]
                    then
                            third="-y"
                    elif [ "$placement_I" -eq "2"  ]
                    then
                            third="-z"
                    fi
    	fi
        echo $first $second $third
        filename=$(echo $image | cut -f 1 -d '.')
        fslswapdim ${image} ${first} ${second} ${third} ${filename}_ro.nii.gz
}


#convert structurals
function best_village_dicom_nii_convert() {
    #author: daelsaid, 08/08/2018;
    dir=$1
    for subj in `ls -d ${dir}/sag*`;
    do
        path=$(dirname $subj)
        subj_id=`echo $(dirname $subj) | cut -d/ -f7`
        new_struct_id=${subj_id}_struct.nii.gz
        summary_with_series_dir=`cat ${path}/summary.txt | grep 184`
        dcm_dir=`echo $summary_with_series_dir | cut -d' ' -f2 | cut -d: -f1`;
        echo $dcm_dir
        cd $subj;
        echo ${dcm_dir}/I0001.dcm ${structs}${new_struct_id};
        mri_convert ${dcm_dir}/I0001.dcm ${structs}${new_struct_id};
        best_struct_fslswapdim ${structs}${new_struct_id}; #reorient to RAS
        cd ${dir};
    done
}


function best_raw_data_orgranization() {
    #author: daelsaid, 08/08/2018;

    find_exams_to_organize;
    for exam in $exams_to_organize; do
        empty_dir $exam; #checks whether exam folder has data in it, if it doesnt it deletes exam directory d/t assumption that weve already organized
    	subj_name=`mri_probedicom --i $exam/anat/001/I0001.dcm | grep PatientName | cut -d' ' -f2`; # create the subject folder to move data into based off of the ID we entered at lucas
    	subj_dir=`readlink -f $(dirname $exam)/${subj_name}`; #subject data path
    	cd $(dirname $exam); #change directory to main direcotry where exam folder is present
    	mkdir ${subj_name}; # makes subject folder that we pulled from the dicom header and what the scanning operator entered as the subject ID
    	mv $exam/* $subj_name; # move all contents from exam folder into the newly created subject folder
    	cd ${subj_dir}/anat; #change directory into anat and begin the organization
    	for dir in `ls -d *`; do
    		echo $dir;
    		seq_name=`mri_probedicom --i $dir/I0001.dcm | grep SeriesDescription | cut -d' ' -f2`;
    		mkdir ../$seq_name;
    		ionice -c 2 -n 3 cp -uvrp $dir ../${seq_name};
    	done
    	cd ${subj_dir};
        #org efiles
    	for efile in `ls E*.*`; do
    		seq_name=` cat $efile | grep "series description" | cut -d' ' -f4`;
    		phys=`echo $efile | cut -b11-16`;
    		mv *$phys* $seq_name;
    	done
        #rename summary and copy tovillage
        mv SUMMARY summary.txt;
        cp summary.txt ${best_data_output_dir}/scan_keys/${subj_name}_scan_summary.txt;
    	cd $(dirname $exam);
    	ionice -c 2 -n 2 bash ${topup}/ApplyTopUp.sh ${subj_name}; #Apply topup
        topup_niis=`ls ${subj_dir}/topup/*tu.nii.gz | wc -l` # check if any topups exist
        if [[ ${topup_niis} -gt 0 ]]; then
            echo "pa/ap present"
        else
            cp ${subj_dir}/topup/*rest*.nii ${best_data_output_dir}/rest;
            cp ${subj_dir}/topup/*colorid.nii ${best_data_output_dir}/colorid;
        fi #copy the .nii of scans if no topup to best output dir
    best_village_dicom_nii_convert ${subj_dir}
    cd ${main_raw_dir};
done &
}





