function [f_compare, critical_point, anagramIdx] = gen_famuli_compare(set_name)
tsv_data = readtable(sprintf('%s.tsv',set_name),'FileType','text','Delimiter','tab');
switch set_name
    case 'Anagram'
        f_compare{1,1} = [24,1,2]; f_compare{1,2} = [6,7,8];
        f_compare{3,1} = [24,1,2]; f_compare{3,2} = [6,7,8];
        f_compare{5,1} = [24,1,2]; f_compare{5,2} = [12,13,14];
        f_compare{7,1} = [24,1,2]; f_compare{7,2} = [12,13,14];
        f_compare{9,1} = [12,13,14]; f_compare{9,2} = [24,1,2];
        f_compare{11,1} = [24,1,2]; f_compare{11,2} = [12,13,14];
        f_compare{13,1} = [24,1,2]; f_compare{13,2} = [6,7,8];
        f_compare{15,1} = [24,1,2]; f_compare{15,2} = [12,13,14];
        f_compare{17,1} = [24,1,2]; f_compare{17,2} = [12,13,14];
        f_compare{19,1} = [24,1,2]; f_compare{19,2} = [12,13,14];
        f_compare{21,1} = [12,13,14]; f_compare{21,2} = [24,1,2];
        f_compare{23,1} = [24,1,2]; f_compare{23,2} = [18,19,20];
        for f = 2:2:24
            f_compare{f,1} = f_compare{f-1,1};
            f_compare{f,2} = f_compare{f-1,2};
        end
        critical_point=[]; anagramIdx=[];
    case 'AnagramPP'
        for f_idx = 1:10
            i1=(f_idx-1)*3+1; i2=(f_idx-1)*3+2; i3=(f_idx-1)*3+3;
            f_compare{f_idx} = [look_for_tsv(tsv_data, i1) + [0:47], look_for_tsv(tsv_data, i2) + [0:47], look_for_tsv(tsv_data, i3) + [0:47]];
        end
        critical_point(1,1,:)=[24,1,2];
        critical_point(1,2,:)=[6,7,8];

        critical_point(2,1,:)=[24,1,2];
        critical_point(2,2,:)=[12,13,14];

        critical_point(3,1,:)=[24,1,2];
        critical_point(3,2,:)=[12,13,14];

        critical_point(4,1,:)=[24,1,2];
        critical_point(4,2,:)=[12,13,14];

        critical_point(5,1,:)=[12,13,14];
        critical_point(5,2,:)=[24,1,2];

        critical_point(6,1,:)=[12,13,14];
        critical_point(6,2,:)=[24,1,2];

        critical_point(7,1,:)=[18,19,20];
        critical_point(7,2,:)=[24,1,2];

        critical_point(8,1,:)=[18,19,20];
        critical_point(8,2,:)=[24,1,2];

        critical_point(9,1,:)=[12,13,14];
        critical_point(9,2,:)=[24,1,2];

        critical_point(10,1,:)=[24,1,2];
        critical_point(10,2,:)=[18,19,20];

        anagramIdx = 1:10;

    case 'AnagramPlus'
        for f_idx = 1:5
            i1=(f_idx-1)*3+1; i2=(f_idx-1)*3+2; i3=(f_idx-1)*3+3;
            f_compare{f_idx} = [look_for_tsv(tsv_data, i1) + [0:47], look_for_tsv(tsv_data, i2) + [0:47], look_for_tsv(tsv_data, i3) + [0:47]];
        end
        critical_point(1,1,:)=[24,1,2];
        critical_point(1,2,:)=[6,7,8];

        critical_point(2,1,:)=[24,1,2];
        critical_point(2,2,:)=[12,13,14];

        critical_point(3,1,:)=[24,1,2];
        critical_point(3,2,:)=[12,13,14];

        critical_point(4,1,:)=[24,1,2];
        critical_point(4,2,:)=[12,13,14];

        critical_point(5,1,:)=[12,13,14];
        critical_point(5,2,:)=[24,1,2];

        anagramIdx(1) = 1;
        anagramIdx(2) = 2;
        anagramIdx(3) = 3;
        anagramIdx(4) = 4;
        anagramIdx(5) = 5;

    case 'AnagramPlus2'
        for f_idx = 1:5
            i1=(f_idx-1)*3+1; i2=(f_idx-1)*3+2; i3=(f_idx-1)*3+3;
            f_compare{f_idx} = [look_for_tsv(tsv_data, i1) + [0:47], look_for_tsv(tsv_data, i2) + [0:47], look_for_tsv(tsv_data, i3) + [0:47]];
        end
        critical_point(1,1,:)=[12,13,14];
        critical_point(1,2,:)=[24,1,2];

        critical_point(2,1,:)=[18,19,20];
        critical_point(2,2,:)=[24,1,2];

        critical_point(3,1,:)=[18,19,20];
        critical_point(3,2,:)=[24,1,2];

        critical_point(4,1,:)=[12,13,14];
        critical_point(4,2,:)=[24,1,2];

        critical_point(5,1,:)=[24,1,2];
        critical_point(5,2,:)=[18,19,20];

        anagramIdx(1) = 6;
        anagramIdx(2) = 7;
        anagramIdx(3) = 8;
        anagramIdx(4) = 9;
        anagramIdx(5) = 10;
end
end