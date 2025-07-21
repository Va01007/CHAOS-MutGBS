import sys
import random


def Order_beds(path_file:str, beds_list:list):
    with open(path_file, "r") as path_f:
        path_list = path_f.readlines()
    ordered_beds = []
    for path in path_list:
        for bed in beds_list:
            if bed[:-4] in path:
                ordered_beds.append(bed)
    return ordered_beds


def parse_files(file:str):
    with open(file, "r") as bed:
        lines = bed.readlines()
    Genome = []
    for line in lines:
        args = line.split()
        Genome.append([args[0], int(args[2])])
    return Genome


def get_span(Chr_length:list, min_length:int):
    if Chr_length[1] <= min_length:
        print("The minimum length of a chromosomal change exceeds the length of a chromosome!")
        sys.exit()
    first_point = 0
    second_point = 0
    while second_point == 0:
        first_point = random.randint(1, Chr_length[1])
        temp_point = random.randint(1, Chr_length[1])
        try:
            if first_point - min_length >= temp_point or first_point + min_length <= temp_point:
                second_point = temp_point
        except:
            pass
    tmp_list = sorted([first_point, second_point])
    return [Chr_length[0], tmp_list[0], tmp_list[1]]


def against_span(Interval:list, Add_length:list):
    if Interval[2] <= Add_length[1]:
        return_list = [Add_length[0], Interval[1], Interval[2]]
    else:
        difference = Interval[2] - Interval[1]
        return_list = [Add_length[0], (Add_length[1] - difference), Add_length[1]]
    return return_list


def check_overlaps(in_list:list):
    chr_dict = {}
    for i in in_list:
        if i[2][0] in chr_dict:
            for pair_num in chr_dict[i[2][0]]:
                if pair_num[1] <= i[2][1] or pair_num[0] >= i[2][2]:
                    chr_dict[i[2][0]].append([i[2][1], i[2][2]])
                else:
                    return False
        else:
            chr_dict[i[2][0]] = [[i[2][1], i[2][2]]]
    return True


def random_intervals(Genome_list:dict, bed_file:list, f_file: str, changes:str, min_len:int):
    if f_file == "NA":
        vals = sorted(list(map(int, changes.split(":"))))
        x = random.randint(vals[0], vals[1])
        mut_types = ["Trans", "Delet", "Inser", "Dupli"]
        checker = False
        while checker == False:
            intervals_list = []
            for i in range(x):
                Choice = (random.choice(mut_types))
                if Choice == "Delet" or Choice == "Dupli":
                    current_assembly = Genome_list[bed_file[0]]
                    current_chr = (random.choice(current_assembly))
                    intervals_list.append([Choice, bed_file[0], get_span(current_chr, min_len)])
                elif Choice == "Inser":
                    current_bed = random.choice(bed_file[1:])
                    current_assembly = Genome_list[current_bed]
                    current_chr = (random.choice(current_assembly))
                    intervals_list.append([Choice, current_bed, get_span(current_chr, min_len)])
                else:
                    current_bed = random.choice(bed_file[1:])
                    current_assembly = Genome_list[current_bed]
                    current_chr = (random.choice(current_assembly))
                    Add_assembly = Genome_list[bed_file[0]]
                    Add_chr = (random.choice(Add_assembly))
                    from_interval = get_span(current_chr, min_len)
                    in_interval = against_span(from_interval, Add_chr)
                    intervals_list.append([Choice, current_bed, from_interval])
                    intervals_list.append(["Delet", bed_file[0], in_interval])
            checker = check_overlaps(intervals_list)
    else:
        with open(f_file, "r") as force_file:
            lines = force_file.readlines()
        intervals_list = []
        for line in lines:
            args = line.split()
            intervals_list.append([args[0], args[1], [args[2], args[3], args[4]]])
        try:
            checker = check_overlaps(intervals_list)
            if checker == True:
                pass
            else:
                print("Intervals are overlapped! Check your file and change it!")
                sys.exit()
        except:
            print("Something wrong with force file!")
            sys.exit()
    return intervals_list


def write_files(intervals_lists:list, gen:dict, beds:list):
    with open("log.txt", "w") as log:
        [log.write(f"{log_interval[0]}\t{log_interval[1]}\t{log_interval[2][0]}\t{log_interval[2][1]}\t{log_interval[2][2]}\n") \
         for log_interval in intervals_lists]
    beds_out = []
    with open(f"{beds[0][:-4]}_edited.bed", "w") as main:
        for chromosome in gen[beds[0]]:
            found_match = False
            for current_interval in intervals_lists:
                if current_interval[1] == beds[0]:
                    if current_interval[2][0] == chromosome[0]:
                        found_match = True
                        if current_interval[0] == "Dupli":
                            main.write(f"{chromosome[0]}\t0\t{chromosome[1]}\n")
                            main.write(f"{chromosome[0]}\t{current_interval[2][1]}\t{current_interval[2][2]}\n")
                        elif current_interval[0] == "Delet":
                            main.write(f"{chromosome[0]}\t0\t{current_interval[2][1]}\n")
                            main.write(f"{chromosome[0]}\t{current_interval[2][2]}\t{chromosome[1]}\n")
                else:
                    beds_out.append(current_interval[1])
            if found_match == False:
                main.write(f"{chromosome[0]}\t0\t{chromosome[1]}\n")
    for bed in set(beds_out):
        with open(f"{bed[:-4]}_edited.bed", "w") as add_bed:
            for other_intervals in intervals_lists:
                if other_intervals[1] == bed:
                    add_bed.write(f"{other_intervals[2][0]}\t{other_intervals[2][1]}\t{other_intervals[2][2]}\n")

if __name__ == "__main__":
    Bed_list = Order_beds(sys.argv[4], sys.argv[5:])
    Genomes = {}
    for bed_file in Bed_list:
        Genomes[bed_file] = parse_files(bed_file)
    intervals = random_intervals(Genomes, Bed_list, sys.argv[1], sys.argv[2], int(sys.argv[3]))
    write_files(intervals, Genomes, Bed_list)