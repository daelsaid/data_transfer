#!/bin/bash

export SPM8DIR="/Applications/spm8_sge"
export PATH=$PATH:/Volumes/Smurf-Village/SoftwareRepository/etkinlab/Stanford-EtkinLab-bitbucket/analysis_pipeline/
export PATH=$PATH:/Volumes/Smurf-Village/Imaging/best_ptsd/scripts/fmri
export PATH=$PATH:/Volumes/Smurf-Village/SoftwareRepository/linux_openmp_64/

main_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd'
eeg_fmri_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/eeg_fmri/hc'
fmri_raw_dir='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/fmri/patient'
fmri_raw_hv='/Volumes/Smurf-Vault/Scanner_Data_From_Lucas/best_ptsd/fmri/hv'
best_data_output_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data';
best_village='/Volumes/Smurf-Village/Imaging/best_ptsd';
fmri_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data/fmri/best_patient_fmri'
eeg_fmri_dir='/Volumes/Smurf-Village/Imaging/best_ptsd/data/eegfmri/best_hc_eeg_fmri';

cd ${main_raw_dir}
exams_to_organize=`find ${eeg_fmri_raw_dir}/ ${fmri_raw_dir}/ ${fmri_raw_hv}/ -maxdepth 3 -name 'E?????'`
echo $exams_to_organize;

function empty_dir(){
  if [ "$(ls -A $1)" ]; then
    echo "dir_has_data"
  else
    rm -rf $1
  fi
}

for exam in $exams_to_organize; do
    empty_dir $exam;
	subj_name=`mri_probedicom --i $exam/anat/001/I0001.dcm | grep PatientName | cut -d' ' -f2`;
	subj_dir=`readlink -f $(dirname $exam)/${subj_name}`;
	cd $(dirname $exam);
	mkdir ${subj_name};
	mv $exam/* $subj_name;
	cd ${subj_dir}/anat;
	for dir in `ls -d *`; do
		echo $dir;
		seq_name=`mri_probedicom --i $dir/I0001.dcm | grep SeriesDescription | cut -d' ' -f2`;
		mkdir ../$seq_name;
		ionice -c 2 -n 3 cp -uvrp $dir ../${seq_name};
	done
	cd ${subj_dir};
	for efile in `ls E*.*`; do
		seq_name=` cat $efile | grep "series description" | cut -d' ' -f4`;
		phys=`echo $efile | cut -b11-16`;
		mv *$phys* $seq_name;
	done
	cd $(dirname $exam);
	#ApplyTopUp.sh ${subj_name};
cd ${main_raw_dir};
done &
