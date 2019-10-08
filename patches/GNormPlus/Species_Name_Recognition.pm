#!perl
#===================================================
# Software: GNormPlus
# Date: 2014/12/25
#===================================================

package GNormPlus;

sub Species_Name_Recognition
{
	my ($input)=@_[0];
	my ($filename)=@_[1];
	my ($dictionary)=@_[2];
	
	my $sentence_extraction="tmp/".$filename.".sentence.xml";
	my $tax_extraction="tmp/".$filename.".tax.xml";
	
	my %regex_hash=();	
	my %dictionary_taxonomy_hash=();
	my %acronym_hash=();
	my %output_tmp_hash=();
	my %output_tmp_acronym_hash=();
	my %guaranteed_hash=();
	my %Priority4HierarchyType_hash = ('genus_name' => 0, 'varietas' => 1, 'subspecies' => 2, 'no rank' => 3, 'species' => 4);
	my %genus_name_hash = ('arabidopsis' => 3702, 'Arabidopsis' => 3702, 'saccharomyces' => 4932, 'Saccharomyces' => 4932, 'escherichia' => 562, 'Escherichia' => 562, 'drosophila' => 7227, 'Drosophila' => 7227, 'xenopus' => 8355, 'Xenopus' => 8355);
	my %pmid_genus_name_hash = ();
	my $count = 1;
	
	open read_regex,"<$dictionary/Species_RegEx.txt";
	while (<read_regex>)
	{
		my $tmp=$_;
		$tmp=~ s/[\n\r]//g;
		$regex_hash{$tmp}=1;
	}
	close read_regex;
	
	open read_dictionary_taxonomy,"<$dictionary/dictionary_taxonomy.txt";
	while (<read_dictionary_taxonomy>)
	{
		my $tmp=$_;
		$tmp=~ s/[\n\r]//g;
		if($tmp=~/^(.+)	(.+)	(.+)$/)
		{
			$dictionary_taxonomy_hash{$1."@".$2}=$3;
			$taxid=$1;
			$taxname=$2;
			$type=$3;
			if($type=~/acronym/)
			{
				$acronym_hash{$taxname}=$taxid;
			}
		}
	}
	close read_dictionary_taxonomy;	
	
	my $sentence_combination="@";
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		my $tmp=$_;
		if($tmp=~/<TEXT pmid='(.+)' sid='(.+)'>(.+)<\/TEXT>/)
		{
			my $pmid=$1;
			my $sid=$2;
			my $sentence=$3;
			$sentence_combination=$sentence_combination.$pmid."|".$sid."\t".$sentence."@";
		}
	}
	close sentence;
	
	$sentence_combination=~ s/[\n\r]/ /g;
	$sentence_combination_org=$sentence_combination;
	foreach my $regex(keys %regex_hash)
	{
		$sentence_combination=$sentence_combination_org;
		if($regex =~/^(.+)	(.+)	(.+)	(.+)$/)
		{ 
			$tax_id=$1;
			$scientific_name=$2;
			$hierarchy_type =$3;
			$regular_expression=$4;
			$regular_expression=~ s/\r//g;
			$genus_name="";
			if ( $scientific_name =~ /^(\w+)\s.+/ ) 
			{
				$genus_name=$1;
			}
			my @array_tagged;	
			while ( $sentence_combination =~ /^(.*\W)($regular_expression)(\W.*)$/i )
			{
				my $front=$1;
				my $species_name=$2;
				my $back=$3;
				#print $species_name."\n";
				if($front =~ /^(.*@)(.+)\|(.+)\t(.*)$/)
				{
					$previous=$1;
					$pmid=$2;
					$sid=$3;
					$front_of_name=$4;
					$str_temp= $species_name;
					$str_temp=~ s/./a/g;
					$sentence_combination = $previous.$pmid."|".$sid."\t".$front_of_name.$str_temp.$back;
					$start_site=length($front_of_name);
					if(length($species_name)>2)
					{
						push (@array_tagged, $pmid."|".$sid."|".$start_site."|".$species_name);
					}
				}
			}				
			foreach $tagged(@array_tagged)
			{
				if($tagged =~ /^(.+)\|(.+)\|(.+)\|(.+)$/)
				{
					$pmid=$1;
					$sid=$2;
					$start_site=$3;
					$species_mention=$4;
					$end_site = length($species_mention)+$start_site;
					my $entity_type=$dictionary_taxonomy_hash{$tax_id."@".$species_mention}; #species->1 ; genus->0 
					my $weight=1;
					if($sid=~/(\_1$|title)/i){$weight=2;}
					my $entity_type_num=2;
					if ($entity_type eq "") {$entity_type="linnaeus";}
					if ($entity_type eq "linnaeus") {$entity_type_num=1;}
					if(exists $acronym_hash{$species_mention})
					{
						$output_tmp_acronym_hash{$acronym_hash{$species_mention}}=$output_tmp_acronym_hash{$acronym_hash{$species_mention}}."<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight'>$species_mention<\/Tax>\n";
					}
					else
					{
						$guaranteed_hash{$tax_id}=1;
						$output_tmp_hash{$pmid."@".$sid."@".$start_site."@".$end_site."@".$Priority4HierarchyType_hash{$hierarchy_type}."@".$entity_type_num}="<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight'>$species_mention<\/Tax>\n";
					}							
					if($genus_name!~/^(human|cell||mouse|rat|yeast|mice|fly)$/) {$pmid_genus_name_hash{$pmid."\t".$genus_name}=$tax_id;}
				}
			} 
		}	
	}
	
	#Matching by genus.
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		my $tmp=$_;
		$tmp=~s/[\n\r]//g;
		if($tmp=~/<TEXT pmid='(.+)' sid='(.+)'>(.+)<\/TEXT>/)
		{
			my $pmid=$1;
			my $sid=$2;
			my $sentence_org=$3;
			my $type=$4;
			foreach my $pmid_genus_name (keys %pmid_genus_name_hash)
			{		
				if($pmid_genus_name=~/^$pmid	(.+)/)
				{
					my $pmid=$1;
					my $genus_name=$1;
					$sentence=" ".$sentence_org." ";	
					my @array_tagged;
					while ( $sentence =~ /^(.*[\W\-\_])($genus_name)([\W\-\_].*)$/i)
					{
						$str1=$1;
						$str2=$2;
						$str3=$3;
						$str_temp = $str2;
						$str_temp =~ s/./a/g;
						$sentence = $str1.$str_temp.$str3;
						push (@array_tagged, $str1."".$str2);
					}		
					foreach $tagged(@array_tagged)
					{
						if($tagged =~ /^(.*[\W\-\_])($genus_name)$/i)
						{
							$str_1=$1;
							$str_2=$2;
							$start_site=length($str_1)-1;
							$end_site =length($str_1)+length($str_2)-1;
							my $weight=1;
							if($sid=~/(\_1$|title)/i){$weight=2;}
							$output_tmp_hash{$pmid."@".$sid."@".$start_site."@".$end_site."\@0\@0"}="<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$genus_name_hash{$genus_name}' entity_type='genus_name' hierarchy_type='genus_name' weight='$weight'>$str_2<\/Tax>\n";
						}
					} 
				}
			}
			foreach my $genus_name (keys %genus_name_hash)
			{		
				$sentence=" ".$sentence_org." ";	
				my @array_tagged;
				while ( $sentence =~ /^(.*[\W\-\_])($genus_name)([\W\-\_].*)$/i)
				{
					$str1=$1;
					$str2=$2;
					$str3=$3;
					$str_temp = $str2;
					$str_temp =~ s/./a/g;
					$sentence = $str1.$str_temp.$str3;
					push (@array_tagged, $str1."".$str2);
				}		
				foreach $tagged(@array_tagged)
				{
					if($tagged =~ /^(.*[\W\-\_])($genus_name)$/i)
					{
						$str_1=$1;
						$str_2=$2;
						$start_site=length($str_1)-1;
						$end_site =length($str_1)+length($str_2)-1;
						my $weight=1;
						if($sid=~/(\_1$|title)/i){$weight=2;}
						$output_tmp_hash{$pmid."@".$sid."@".$start_site."@".$end_site."\@0\@0"}="<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$genus_name_hash{$genus_name}' entity_type='genus_name' hierarchy_type='genus_name' weight='$weight'>$str_2<\/Tax>\n";
					}
				}
			}
		}
	}
	close sentence;

	#Filtering of repeat recordds and output
	open Tax,">$tax_extraction";
	foreach $output (keys %output_tmp_hash)
	{
		my @split_1=split("@",$output);
		my $mode=0;
		foreach $output2 (keys %output_tmp_hash)
		{
			my @split_2=split("@",$output2);
			if($split_2[0] eq $split_1[0] && $split_2[1] eq $split_1[1] && (($split_2[3]>$split_1[3] && $split_2[2]<=$split_1[2]) || ($split_2[3]>=$split_1[3] && $split_2[2]<$split_1[2])))
			{
				$mode=1;
			}
			elsif($split_2[0] eq $split_1[0] && $split_2[1] eq $split_1[1] && $split_2[3]==$split_1[3] && $split_2[2]==$split_1[2] && $split_2[4]>$split_1[4])
			{
				$mode=1;
			}
			elsif($split_2[0] eq $split_1[0] && $split_2[1] eq $split_1[1] && $split_2[3]==$split_1[3] && $split_2[2]==$split_1[2] && $split_2[4]==$split_1[4] && $split_2[5]>$split_1[5])
			{
				$mode=1;
			}
			if($mode==1)
			{	
				break;
			}
		}
		if($mode==0)
		{
			print Tax $output_tmp_hash{$output};
		}
	}
	foreach $guaranteed(keys %guaranteed_hash)
	{
		print Tax $output_tmp_acronym_hash{$guaranteed};
	}
	close Tax;	
		
	return 1;
}

sub CellLine_Recognition
{
	my ($input)=@_[0];
	my ($filename)=@_[1];
	my ($dictionary)=@_[2];
	
	my $sentence_extraction="tmp/".$filename.".sentence.xml";
	my $tax_extraction="tmp/".$filename.".tax.xml";
	
	my %taxonomy_hash=();
	my %cell_line_hash=();
	my %cell_line_hierarchy_hash=();
	my %output_hash=();
	my %regions_hash=();
	
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		my $tmp=$_;
		my %filtering_hash=();
		if($tmp=~/<TEXT pmid='(.+)' sid='(.+)'>(.+)<\/TEXT>/)
		{
			my $pmid=$1;
			my $sid=$2;
			my $sentence=$3;
			my $sentence_org=$sentence;
			while($sentence_org=~/^(.*\W)([Cc]ell[s]{0,1})(\W.*)$/)
			{
				$s1=$1;
				$s2=$2;
				$s3=$3;
				my $start=0;
				if(length($s1)>30){$start-=30;}else{$start-=length($s1);}
				$str1=substr($s1,$start,length($s1));
				$str2=$s2;
				$str3=substr($s3,0,30);
				$str1=~s/aaaa/cell/g;
				$str3=~s/aaaa/cell/g;
				$regions_hash{$str1.$str2.$str3}=1;
				$sentence_org=$s1."aaaa".$s3;
			}
		}
	}
	close sentence;
		
	open cell_line,"<$dictionary/cell_line.txt";
	while(<cell_line>)
	{
		my $tmp=$_;
		if($tmp=~/^(.+)	(.+)	(.+)$/)
		{
			my $cellname=$1;
			$cellname=~s/[\n\r]//g;
			my $taxid=$2;
			$taxid=~s/[\n\r]//g;
			my $hierarchy_type=$3;
			$hierarchy_type=~s/[\n\r]//g;
			if(length($cellname)>=3)
			{
				$cellname =~s/[\_\-\W]/ /g;
				$cell_line_hash{lc($cellname)}=$taxid;
				$cell_line_hierarchy_hash{lc($cellname)}=$hierarchy_type;
			}
		}
	}	
	
	#matching by cell line.
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		my $tmp=$_;
		if($tmp=~/<TEXT pmid='(.+)' sid='(.+)'>(.+)<\/TEXT>/)
		{
			my $pmid=$1;
			my $sid=$2;
			my $sentence_org=$3;
			my $sentence=$3;
			#$sentence_org=lc($sentence_org);
			$sentence=~ s/[\n\r]/ /g;
			$sentence=~ s/[\_\-\(\)\[\]\'!@\#\$\&\%:;\\=><\"]/ /g;
			$sentence="@".$sentence."@";
				
			my %output_tmp_hash=();
			my %filtering_hash=();
			foreach $entry (keys %cell_line_hash)
			{
				$entry_rev=$entry;
				$entry_rev=~ s/^(.*)([A-Za-z])([0-9])(.*)$/$1$2 $3$4/g;
				$entry_rev=~ s/^(.*)([0-9])([A-Za-z])(.*)$/$1$2 $3$4/g;
				$entry_rev2=$entry;
				$entry_rev2=~ s/ //g;
				$regular_expression="(".$entry."|".$entry_rev."|".$entry_rev2.")";
				while( $sentence =~ /^(.*\W)($regular_expression)(\W.*)/i)
				{
					my $str_1=$1;
					#$str_2=$2;
					my $str_3=$3;
					my $str_2=substr($sentence_org,length($str_1)-1,length($2));
					$str_temp= $str_2;
					$str_temp=~ s/./a/g;
					$sentence = $str_1.$str_temp.$str_3;
					$start_site=length($str_1)-1;
					$end_site =length($str_1)+length($str_2)-1;
					my $weight=1;
					if($sid=~/(\_1$|title)/i)
					{
						$weight=2;
					}
					$output_tmp_hash{$pmid."@".$sid."@".$start_site."@".$end_site}="<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$cell_line_hash{$entry}' entity_type='cell_line' hierarchy_type='$cell_line_hierarchy_hash{$entry}' weight='$weight'>$str_2<\/Tax>\n";
				} 
			}
			foreach $output (keys %output_tmp_hash)
			{	
				my @split_1=split("@",$output);
				my $mode=0;	
				foreach $output2 (keys %output_tmp_hash)
				{	my @split_2=split("@",$output2);
					if($split_2[0] eq $split_1[0] && $split_2[1] eq $split_1[1])
					{
						if( ($split_2[3]>$split_1[3] && $split_2[2]<=$split_1[2]) || ($split_2[3]>=$split_1[3] && $split_2[2]<$split_1[2]) )
						{
							$mode=1;
						}
					}
					if($mode==1){break;}
				}
				if($mode==0)
				{
					$output_hash{$output}=$output_tmp_hash{$output};
				}
			}
		}
	}	
	close sentence;
	
	open Tax,">>$tax_extraction";
	foreach my $output (keys %output_hash)
	{
		if($output_hash{$output}=~/>(.+?)</)
		{
			$entity = $1;
			my $mode=0;
			$entity=~s/([\W\-\_])/\\$1/g;
			foreach my $region (keys %regions_hash)
			{
				$region=~s/\W/ /g;
				if(lc($region)=~/$entity/i)
				{
					$mode=1;
				}
			}
			if($mode==1)
			{
				print Tax $output_hash{$output};
			}
		}
	}
	close Tax;
	return 1;
}

#### Disambiguation by Co-occurrence ####
sub Disambiguation_occurrence
{
	my ($input)=@_[0];
	my ($filename)=@_[1];
	my ($dictionary)=@_[2];
	
	my $sentence_extraction="tmp/".$filename.".sentence.xml";
	my $tax_extraction="tmp/".$filename.".tax.xml";
	
	my %Mention2SubType_hash=();
	my %tax_tmp_hash=();
	my %output_hash=();
	my %SubType2Info_hash=();
	my %Abb2Info_hash=();
	my %exists_species_hash=();
	my %Priority4Strain_hash = ('substrain' => 0, 'substr' => 0, 'strain' => 1, 'str' => 1, 'subspecies' => 2, 'subsp' => 2, 'variant' => 2, 'var' => 2, 'pathovar' => 2, 'pv' => 2, 'biovar' => 2,'bv' => 2);
	
	open sub_type,"<$dictionary/sub_type.txt";
	while(<sub_type>)
	{
		my $sub_type=$_;
		$sub_type=~s/[\n\r]//g;
		if($sub_type=~/^(.+)\:\:(.+)$/)
		{
			$Mention2SubType_hash{lc($1)}=$2;
		}
	}
	close sub_type;
	
	#Read Ab3P
	my %Full2Abb_hash=();
	my $pmid="";
	open Abb,"<tmp/".$filename.".Ab3P";
	while(<Abb>)
	{
		my $tmp=$_;
		$tmp=~s/[\n\r]//g;
		if($tmp=~/^([^\|]+)$/)
		{
			$pmid=$1;
			$tmp=<Abb>; #sentences
		}
		elsif($tmp=~/^  (.+)\|(.+)\|/)
		{
			my $Abb=$1;
			my $FN=$2;
			$Full2Abb_hash{$pmid."\t".lc($FN)}=lc($Abb);
		}
	}
	close Abb;
		
	open Tax,"<$tax_extraction";
	while(<Tax>)
	{
		my $tax=$_;
		$tax_tmp_hash{$tax}=1;
		if($tax=~/<Tax pmid='(.+)' sid='(.+)' start='(.+)' end='(.+)' tax_id='(.+)' entity_type='(.+)' hierarchy_type='(.+)' weight='(.+)'>(.+)<\/Tax>/)
		{
			my $pmid = $1;
			my $sid = $2;
			my $start_site = $3;
			my $end_site = $4;
			my $tax_id = $5;
			my $entity_type = $6;
			my $hierarchy_type = $7;
			my $weight = $8;
			my $entity = $9;
			my $limitation=1000;
			
			if(exists $Full2Abb_hash{$pmid."\t".lc($entity)})
			{
				$Abb2Info_hash{$Full2Abb_hash{$pmid."\t".lc($entity)}}=$tax_id."\t".$entity_type."\t".$hierarchy_type;
			}
			
			$exists_species_hash{$pmid."@".$sid."@".$start_site."@".$end_site}=1;
			
			if(not exists $Mention2SubType_hash{lc($entity)})
			{
				$output_hash{$tax}=1;
			}
			else # subtype exist
			{
				open Tax_tmp,"<$tax_extraction";
				while(<Tax_tmp>)
				{
					my $tax_tmp=$_;
					if($tax_tmp=~/<Tax pmid='(.+)' sid='(.+)' start='(.+)' end='(.+)' tax_id='(.+)' entity_type='(.+)' hierarchy_type='(.+)' weight='(.+)'>(.+)<\/Tax>/)
					{
						my $next_start = $3;
						my $pmid_n = $1;
						my $sid_n = $2;
						if(($pmid_n eq $pmid) && ($sid_n eq $sid) && ($next_start > $end_site) && $next_start < $limitation)
						{
							$limitation = $next_start;
						}
					}
				}
				my $searching_region="";
				open sentence,"<$sentence_extraction";
				while(<sentence>)
				{
					my $tmp=$_;
					if($tmp=~/<TEXT pmid='$pmid' sid='$sid'>(.+)<\/TEXT>/)
					{
						$sentence = $1;
						#$sentence=lc($sentence);
						$searching_region = " ".substr ($sentence, ($end_site) , ($limitation-$end_site-1) )." ";
					}
				}
				close sentence;
				
				#Check all subtypes for the extracted Tax entity
				my @subtype_array=split("\t",$Mention2SubType_hash{lc($entity)});
				my $match_mode=0;
				my %PmidStartLast2Priority_hash=();
				my %PmidStartLast2output_hash=();
				foreach my $each_subtype(@subtype_array)
				{
					if($each_subtype=~/^(.+)\|(.+)\|(.+)\|(.+)$/ && $tax_id ne $1)
					{
						my $subtype_tax_id = $1;
						my $subtype_entity = $2;
						my $subtype_type = $3;
						my $subtype_hierarchy_type = $4;
						$subtype_entity=~s/[\W\_\-]/\[\\W\\\_\\\-\]/g;
						if ($searching_region =~ /^(.*[\W\-\_](subspecies|substrain|strain|variant|biovar|pathovar|substr|subsp|str|var|pv|bv)[\W\-\_])($subtype_entity)[\W\-\_]/i)
						{
							$match_mode=1;
							my $pre=$1;
							my $StrainType=$2;
							$subtype_entity=$3;
							$start=$end_site+length($pre)-1;
							$last=$end_site+length($pre)+length($subtype_entity)-1;
							if(not exists $exists_species_hash{$pmid."@".$sid."@".$start."@".$last})
							{
								if((exists $PmidStartLast2Priority_hash{$pmid."\t".$start_site."\t".$end_site}))
								{
									if($Priority4Strain_hash{$StrainType}<$PmidStartLast2Priority_hash{$pmid."\t".$start_site."\t".$end_site})
									{
										delete $output_hash{$PmidStartLast2utput_hash{$pmid."\t".$start_site."\t".$end_site}};
										$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$last' tax_id='$subtype_tax_id' entity_type='$StrainType' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$subtype_entity</Tax>\n"}=1;
										$exists_species_hash{$pmid."@".$sid."@".$start."@".$last}=1;
										$subtype_entity=~s/[\W\-\_]//g;
										$SubType2Info_hash{$subtype_entity}=$subtype_tax_id."\t".$StrainType."\t".$subtype_hierarchy_type;
									}
								}
								else
								{
									$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$last' tax_id='$subtype_tax_id' entity_type='$StrainType' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$subtype_entity</Tax>\n"}=1;
									$exists_species_hash{$pmid."@".$sid."@".$start."@".$last}=1;
									$subtype_entity=~s/[\W\-\_]//g;
									$SubType2Info_hash{$subtype_entity}=$subtype_tax_id."\t".$StrainType."\t".$subtype_hierarchy_type;
								}
								$PmidStartLast2Priority_hash{$pmid."\t".$start_site."\t".$end_site}=$Priority4Strain_hash{$StrainType};
								$PmidStartLast2output_hash{$pmid."\t".$start_site."\t".$end_site}="<Tax pmid='$pmid' sid='$sid' start='$start' end='$last' tax_id='$subtype_tax_id' entity_type='$StrainType' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$subtype_entity</Tax>\n";
							}
							break;
						}
						elsif($searching_region=~/^(.*[\W\-\_])($subtype_entity)[\W\-\_]/i && length($2)>=3 ) #No subtitle, but subtype entity length >3
						{
							$match_mode=1;
							my $pre=$1;
							$subtype_entity=$2;
							$start=$end_site+length($pre)-1;
							$last=$end_site+length($pre)+length($subtype_entity)-1;
							if(not exists $exists_species_hash{$pmid."@".$sid."@".$start."@".$last})
							{
								$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$last' tax_id='$subtype_tax_id' entity_type='$subtype_type' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$subtype_entity</Tax>\n"}=1;
								$exists_species_hash{$pmid."@".$sid."@".$start."@".$last}=1;
								$subtype_entity=~s/[\W\-\_]//g;
								$SubType2Info_hash{$subtype_entity}=$subtype_tax_id."\t".$subtype_type."\t".$subtype_hierarchy_type;
								$PmidStartLast2Priority_hash{$pmid."\t".$start_site."\t".$end_site}=3;#lowest priority
								$PmidStartLast2output_hash{$pmid."\t".$start_site."\t".$end_site}="<Tax pmid='$pmid' sid='$sid' start='$start' end='$last' tax_id='$subtype_tax_id' entity_type='$StrainType' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$subtype_entity</Tax>\n";
							}
							break;
						}
					}
				}
				if($match_mode==0)
				{
					$output_hash{$tax}=1;
				}
			}
		}
	}
	close Tax;

	my %exists_hash=();
	open Tax,">$tax_extraction";	
	foreach my $output(keys %output_hash)
	{
		print Tax $output;
		if($output=~/<Tax pmid='(.+?)' sid='(.+?)' start='(.+?)' end='(.+?)'/)
		{
			$exists_hash{$1."\t".$2."\t".$3."\t".$4}=1;
		}
	}	
	
	my %combine_hash=();
	foreach my $tmp(keys %Abb2Info_hash){$combine_hash{$tmp}=$Abb2Info_hash{$tmp};}
	foreach my $tmp(keys %SubType2Info_hash){$combine_hash{$tmp}=$SubType2Info_hash{$tmp};}
	
	#Sub-type & Abb extension in Text
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		$tmp=$_;
		if($tmp=~/^<TEXT pmid='(.+)' sid='(.+)'>(.+)<\/TEXT>$/)
		{
			$pmid=$1;
			$sid=$2;
			$sentence = " ".$3." ";
			
			foreach my $SubType (keys %combine_hash)
			{
				my $SubType_org=$SubType;
				$SubType=~s/[\W\-\_]/\[\\W\\\-\\\_\]/g;
				while ( $sentence =~ /^(.*[\W\-\_])($SubType)([\W\-\_].*)$/i)
				{
					my $str_1=$1;
					my $str_2=$2;
					my $str_3=$3;
					my $start_site=length($str_1)-1;
					my $end_site =length($str_1)+length($str_2)-1;

					$str_temp= $str_2;
					$str_temp=~ s/./a/g;
					$sentence = $str_1.$str_temp.$str_3;
					
					my $weight=1;
					if($sid=~/(\_1$|title)/i){$weight=2;}
					my $entity_type_num=2;
					if(not exists $exists_species_hash{$sid."@".$start_site."@".$end_site})
					{
						my ($subtype_tax_id,$subtype_type,$subtype_hierarchy_type)=($combine_hash{$SubType_org}=~/^(.+)	(.+)	(.+)$/);
						if(not exists $exists_hash{$pmid."\t".$sid."\t".$start_site."\t".$end_site})
						{
							print Tax "<Tax pmid='$pmid' sid='$sid' start='$start_site' end='$end_site' tax_id='$subtype_tax_id' entity_type='$subtype_type' hierarchy_type='$subtype_hierarchy_type' weight='$weight'>$str_2</Tax>\n";
						}
					}
				}
			} 
		}
	}
	close sentence;
	close Tax;
		
	return 1;
}

sub Filtering
{
	my ($input)=@_[0];
	my ($filename)=@_[1];
	my ($dictionary)=@_[2];
	
	my $sentence_extraction="tmp/".$filename.".sentence.xml";
	my $tax_extraction="tmp/".$filename.".tax.xml";
	
	my %sentence_hash=();
	my %stopword_hash=();
	my %output_hash=();
	
	open sentence,"<$sentence_extraction";
	while(<sentence>)
	{
		my $tmp=$_;
		if($tmp=~/^<.+ pmid=\'(.*)\' sid=\'(.*)\'>(.+)<\/(.+)>$/)
		{
			my $pmid=$1;
			my $sid=$2;
			my $sentence_org=$3;
			my $type=$4;
			#$sentence_org=lc($sentence_org);
			$sentence_org=~ s/[\n\r]/ /g;
			$sentence_org =~s/[^0-9^A-Za-z]/ /g;
			$sentence_hash{$pmid."\t".$sid}=$sentence_org;
		}
	}
	close sentence;
	
	open stoplist,"<$dictionary/stoplist_species.txt";
	while(<stoplist>)
	{
		$stopentry=$_;
		
		if($stopentry =~/(.+)\t(.+)/)
		{
			$tax_id=$1;
			$stopword=$2;
			$stopword_hash{$stopword}=$tax_id;		
		}
	}
	close stoplist;
	
	open Tax,"<$tax_extraction";
	while(<Tax>)
	{
		my $delete_query="";
		my $tmp=$_;
		my $filtering_mode=0;
		
		if($tmp=~/<Tax pmid='(.*)' sid='(.*)' start='(.*)' end='(.*)' tax_id='(.*)' entity_type='(.*)' hierarchy_type='(.*)' weight='(.*)'>(.*)<\/Tax>/)
		{
			my $pmid=$1;
			my $sid=uc($2);
			my $start=$3;
			my $end=$4;
			my $tax_id=$5;
			my $entity_type=$6;
			my $hierarchy_type=$7;
			my $weight=$8;
			my $entity=$9;
			my $get_sentence=$sentence_hash{$pmid."\t".$sid};
			my $entity_tmp=$entity;
			$entity_tmp=~s/[\(\)]/\./g;
			#Fitering by anti_serum
			if ($get_sentence =~/([Aa]nti|[Aa]ntibody|[Aa]ntibodies|[Ss]erum|[Pp]olyclonal|[Mm]onoclonal|IgG)\s$entity_tmp/)
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='anti_serum'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			elsif ($get_sentence =~/$entity_tmp\s([Aa]nti|[Aa]ntibody|[Aa]ntibodies|[Ss]erum|[Pp]olyclonal|[Mm]onoclonal|IgG)/)
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='anti_serum'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			elsif ($get_sentence =~/$entity_tmp\s\S+\s([Aa]nti|[Aa]ntibody|[Aa]ntibodies|[Ss]erum|[Pp]olyclonal|[Mm]onoclonal|IgG)/)
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='anti_serum'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			elsif ($get_sentence =~/([Aa]nti|[Aa]ntibody|[Aa]ntibodies|[Ss]erum|[Pp]olyclonal|[Mm]onoclonal|IgG)\s\S+\s$entity_tmp/)
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='anti_serum'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			
			#Fitering by experiment
			if (($get_sentence =~/[Yy]east[\-\s]two[\-\s]hybrid/ || $get_sentence =~/[Yy]east[\-\s]2[\-\s]hybrid/) && $entity eq "yeast")
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='experiment'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			
			#Fitering by stoplist
			if(exists $stopword_hash{$entity})
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type='stoplist'>$entity</Tax>\n"}=0;
				$filtering_mode=1;
			}
			
			if($filtering_mode==0)
			{
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id' entity_type='$entity_type' hierarchy_type='$hierarchy_type' weight='$weight' filtering_type=''>$entity</Tax>\n"}=0;
				$output_hash{"<Tax pmid='$pmid' sid='$sid' start='$start' end='$end' tax_id='$tax_id'>$entity</Tax>\n"}=1;
			}
		}	
	}
	close Tax;
	open Tax,">$tax_extraction";
	foreach $output(keys %output_hash)
	{
		if($output_hash{$output}==1)
		{
			print Tax $output;
		}
	}
	close Tax;
	return 1;
}

return 1;
