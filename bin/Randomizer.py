import sys
import random


def parse_files(file:str):
    with open(file, "r") as bed:
        lines = bed.readlines()
    Genome = []
    for line in lines:
        args = line.split()
        Genome.append([args[0], int(args[2])])
    return Genome


def get_span(Chr_length:list):
    first_point = 0
    second_point = 0
    while second_point == 0:
        first_point = random.randint(1, Chr_length[1])
        temp_point = random.randint(1, Chr_length[1])
        try:
            if first_point - 3000000 >= temp_point or first_point + 3000000 <= temp_point:
                second_point = temp_point
        except:
            print("Chromosome length is to small")
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


def random_intervals(Genome_list:dict, bed_file:list):
    x = random.randint(1,10)
    mut_types = ["Trans", "Delet", "Inser", "Dupli"]

    checker = False
    while checker == False:
        intervals_list = []
        for i in range(x):
            Choice = (random.choice(mut_types))
            if Choice == "Delet" or Choice == "Dupli":
                current_assembly = Genome_list[bed_file[0]]
                current_chr = (random.choice(current_assembly))
                intervals_list.append([Choice, bed_file[0], get_span(current_chr)])
            elif Choice == "Inser":
                current_bed = random.choice(bed_file[1:])
                current_assembly = Genome_list[current_bed]
                current_chr = (random.choice(current_assembly))
                intervals_list.append([Choice, bed_file[0], get_span(current_chr)])
            else:
                current_bed = random.choice(bed_file[1:])
                current_assembly = Genome_list[current_bed]
                current_chr = (random.choice(current_assembly))
                Add_assembly = Genome_list[bed_file[0]]
                Add_chr = (random.choice(Add_assembly))
                from_interval = get_span(current_chr)
                in_interval = against_span(from_interval, Add_chr)
                intervals_list.append([Choice, current_bed, from_interval])
                intervals_list.append(["Delet", bed_file[0], in_interval])
        checker = check_overlaps(intervals_list)
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
                if other_intervals[1] == beds[0]:
                    add_bed.write(f"{other_intervals[2][0]}\t{other_intervals[2][1]}\t{other_intervals[2][2]}\n")

if __name__ == "__main__":
    Bed_list = sys.argv[1:]
    Genomes = {}
    for bed_file in Bed_list:
        Genomes[bed_file] = parse_files(bed_file)
    intervals = random_intervals(Genomes, Bed_list[::-1])
    write_files(intervals, Genomes, Bed_list[::-1])